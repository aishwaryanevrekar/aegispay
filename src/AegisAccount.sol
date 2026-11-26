// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Minimal, IIdentityRegistry, IPaymentRouter} from "./interfaces/IAevum.sol";

/// @title AegisAccount
/// @notice A tUSD8 smart account that lets a principal delegate *limited*,
///         revocable payment authority to an autonomous agent (scoped session key).
/// @dev Security model:
///      - owner is immutable and is the only party that can issue/revoke keys
///      - every agent payment is checked against: active flag, expiry, per-tx cap,
///        cumulative cap, payee allowlist, ERC-8004 identity and (optionally) a
///        single-use human approval for high-value payments
///      - checks-effects-interactions is used for the token transfer
///      - no delegatecall, no upgradeability, no arbitrary calls by agents
contract AegisAccount {
    struct Session {
        bool active;
        uint256 totalCap;          // lifetime spend allowed for this key
        uint256 spent;             // amount already spent
        uint256 perTxCap;          // maximum single payment
        uint256 expiry;            // unix timestamp after which the key is void
        address recipient;         // locked payee (address(0) = any verified payee)
        bool recipientLocked;
        uint256 agentId;           // ERC-8004 identity bound to this key (0 = none)
        uint256 approvalThreshold; // payments above this need owner approval (0 = none)
        uint256 nonce;             // increments per payment -> ordered audit trail
    }

    address public immutable owner;
    IERC20Minimal public immutable token;
    IIdentityRegistry public immutable identity;
    address public immutable reputation;
    address public router;

    mapping(address => Session) public sessions;
    mapping(bytes32 => bool) public approvals; // single-use approval receipts

    event Deposited(address indexed from, uint256 amount);
    event SessionIssued(
        address indexed agent,
        uint256 indexed agentId,
        uint256 totalCap,
        uint256 perTxCap,
        uint256 expiry,
        address recipient,
        uint256 approvalThreshold
    );
    event SessionRevoked(address indexed agent);
    event PaymentApproved(
        bytes32 indexed opHash,
        address indexed agent,
        address indexed recipient,
        uint256 amount,
        uint256 nonce
    );
    event PaymentExecuted(
        address indexed agent,
        uint256 indexed agentId,
        address indexed recipient,
        uint256 amount,
        uint256 nonce
    );
    event RouterUpdated(address indexed router);
    event EmergencyWithdraw(address indexed to, uint256 amount);

    error Unauthorized();
    error ZeroAddress();
    error ZeroAmount();
    error SessionInactive();
    error SessionExpired();
    error CapExceeded();
    error AmountExceedsPerTxCap();
    error RecipientNotAllowed();
    error IdentityNotAuthorized();
    error IdentityOwnerMismatch();
    error RouterNotSet();
    error TransferFailed();
    error ExpiryInPast();
    error InvalidCaps();
    error ApprovalRequired();
    error ApprovalAlreadyUsed();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor(address owner_, address token_, address identity_, address reputation_, address router_) {
        if (owner_ == address(0) || token_ == address(0) || identity_ == address(0) || router_ == address(0)) {
            revert ZeroAddress();
        }
        owner = owner_;
        token = IERC20Minimal(token_);
        identity = IIdentityRegistry(identity_);
        reputation = reputation_;
        router = router_;
    }

    function setRouter(address router_) external onlyOwner {
        if (router_ == address(0)) revert ZeroAddress();
        router = router_;
        emit RouterUpdated(router_);
    }

    /// @notice Pull tUSD8 from the principal into the account. Requires ERC-20 approval.
    function deposit(uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();
        emit Deposited(msg.sender, amount);
        if (!token.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
    }

    /// @notice Issue or replace a scoped session key for an agent.
    /// @dev If agentId != 0, the ERC-8004 identity must be owned by this account's
    ///      principal and must authorize the runtime `agent` address.
    function issueSession(
        address agent,
        uint256 agentId,
        uint256 totalCap,
        uint256 perTxCap,
        uint256 expiry,
        address recipient,
        uint256 approvalThreshold
    ) external onlyOwner {
        if (agent == address(0)) revert ZeroAddress();
        if (totalCap == 0 || perTxCap == 0 || perTxCap > totalCap) revert InvalidCaps();
        // forge-lint: disable-next-line(block-timestamp)
        if (expiry <= block.timestamp) revert ExpiryInPast();

        if (agentId != 0) {
            if (!identity.isAuthorized(agentId, agent)) revert IdentityNotAuthorized();
            if (identity.ownerOf(agentId) != owner) revert IdentityOwnerMismatch();
        }

        sessions[agent] = Session({
            active: true,
            totalCap: totalCap,
            spent: 0,
            perTxCap: perTxCap,
            expiry: expiry,
            recipient: recipient,
            recipientLocked: recipient != address(0),
            agentId: agentId,
            approvalThreshold: approvalThreshold,
            nonce: 0
        });

        emit SessionIssued(agent, agentId, totalCap, perTxCap, expiry, recipient, approvalThreshold);
    }

    /// @notice Instantly disable an agent key. Funds remain in the account.
    function revokeSession(address agent) external onlyOwner {
        sessions[agent].active = false;
        emit SessionRevoked(agent);
    }

    /// @notice Pre-approve one specific high-value payment (single use).
    /// @param nonce The agent's *next* nonce (read `sessions[agent].nonce + 1`).
    function approvePayment(address agent, address recipient, uint256 amount, uint256 nonce) external onlyOwner {
        bytes32 opHash = paymentHash(agent, recipient, amount, nonce);
        if (approvals[opHash]) revert ApprovalAlreadyUsed();
        approvals[opHash] = true;
        emit PaymentApproved(opHash, agent, recipient, amount, nonce);
    }

    /// @notice Agent (or owner) sends tUSD8 directly to a recipient.
    function pay(address recipient, uint256 amount) external {
        if (msg.sender != owner) _authorize(msg.sender, recipient, amount);
        else if (amount == 0) revert ZeroAmount();
        _transferOut(recipient, amount);
    }

    /// @notice Agent pays a verified merchant through the settlement router.
    /// @dev This is the primary demo flow (Confirmation of Payee + reputation).
    function payWithService(address merchant, uint256 amount, bytes32 serviceRef) external {
        if (merchant == address(0)) revert ZeroAddress();
        if (router == address(0)) revert RouterNotSet();
        if (msg.sender != owner) _authorize(msg.sender, router, amount);
        else if (amount == 0) revert ZeroAmount();

        uint256 agentId = msg.sender == owner ? 0 : sessions[msg.sender].agentId;
        _transferOut(router, amount);
        IPaymentRouter(router).settle(address(this), merchant, amount, serviceRef, agentId);
    }

    /// @notice Emergency escape hatch for the principal only (e.g. migration).
    function emergencyWithdraw(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        emit EmergencyWithdraw(to, amount);
        if (!token.transfer(to, amount)) revert TransferFailed();
    }

    // --- views -------------------------------------------------------------

    function remainingBudget(address agent) external view returns (uint256) {
        Session storage s = sessions[agent];
        if (!s.active || block.timestamp > s.expiry) return 0;
        return s.totalCap - s.spent;
    }

    function isSessionValid(address agent) external view returns (bool) {
        Session storage s = sessions[agent];
        return s.active && block.timestamp <= s.expiry && s.spent < s.totalCap;
    }

    function paymentHash(address agent, address recipient, uint256 amount, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encode(agent, recipient, amount, nonce));
    }

    // --- internals ---------------------------------------------------------

    function _authorize(address agent, address to, uint256 amount) internal {
        Session storage s = sessions[agent];
        if (!s.active) revert SessionInactive();
        if (block.timestamp > s.expiry) revert SessionExpired();
        if (amount == 0 || amount > s.perTxCap) revert AmountExceedsPerTxCap();
        if (s.spent + amount > s.totalCap) revert CapExceeded();
        if (s.recipientLocked && to != s.recipient) revert RecipientNotAllowed();

        if (s.approvalThreshold != 0 && amount > s.approvalThreshold) {
            bytes32 opHash = paymentHash(agent, to, amount, s.nonce + 1);
            if (!approvals[opHash]) revert ApprovalRequired();
            delete approvals[opHash]; // single-use -> idempotent replay protection
        }
    }

    function _transferOut(address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();
        Session storage s = sessions[msg.sender];
        bool isAgent = msg.sender != owner;

        // effects before interaction
        if (isAgent) {
            s.spent += amount;
            s.nonce += 1;
        }
        emit PaymentExecuted(msg.sender, isAgent ? s.agentId : 0, to, amount, isAgent ? s.nonce : 0);
        if (!token.transfer(to, amount)) revert TransferFailed();
    }
}
