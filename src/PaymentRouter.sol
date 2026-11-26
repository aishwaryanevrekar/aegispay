// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Minimal, IIdentityRegistry, IReputationRegistry} from "./interfaces/IAevum.sol";

/// @title PaymentRouter
/// @notice Merchant registry + settlement hook. Implements the "Confirmation of
///         Payee" pattern: a merchant can only receive funds if its address is
///         bound to an ERC-8004 identity. The router receives tUSD8 from an
///         AegisAccount, forwards it to the verified merchant, emits a receipt
///         and writes reputation entries for both agent and merchant identities.
contract PaymentRouter {
    IERC20Minimal public immutable token;
    IReputationRegistry public immutable reputation;
    IIdentityRegistry public immutable identity;

    mapping(address => string) public merchantName;
    mapping(address => uint256) public merchantIdentity; // 0 = not verified
    mapping(address => uint256) public merchantPayments;
    uint256 public totalSettled;

    event MerchantRegistered(address indexed merchant, string name, uint256 indexed identityId);
    event ServiceSettled(
        address indexed account,
        address indexed merchant,
        uint256 amount,
        bytes32 indexed serviceRef,
        uint256 agentId
    );

    error ZeroAddress();
    error ZeroAmount();
    error TransferFailed();
    error IdentityNotAuthorized();
    error UnknownMerchant();

    constructor(address token_, address reputation_, address identity_) {
        if (token_ == address(0) || identity_ == address(0)) revert ZeroAddress();
        token = IERC20Minimal(token_);
        reputation = IReputationRegistry(reputation_);
        identity = IIdentityRegistry(identity_);
    }

    /// @notice Register a payee. Confirmation of Payee: the caller must control
    ///         the ERC-8004 identity's authorized runtime address.
    function registerMerchant(string calldata name, uint256 identityId) external {
        if (msg.sender == address(0)) revert ZeroAddress();
        if (!identity.isAuthorized(identityId, msg.sender)) revert IdentityNotAuthorized();
        merchantName[msg.sender] = name;
        merchantIdentity[msg.sender] = identityId;
        emit MerchantRegistered(msg.sender, name, identityId);
    }

    /// @notice Called by an AegisAccount right after it transfers `amount` tUSD8 here.
    function settle(address account, address merchant, uint256 amount, bytes32 serviceRef, uint256 agentId) external {
        if (merchant == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        uint256 merchantId = merchantIdentity[merchant];
        if (merchantId == 0) revert UnknownMerchant();

        // effects before interaction
        merchantPayments[merchant] += amount;
        totalSettled += amount;

        emit ServiceSettled(account, merchant, amount, serviceRef, agentId);
        if (!token.transfer(merchant, amount)) revert TransferFailed();

        if (address(reputation) != address(0)) {
            if (agentId != 0) reputation.giveFeedback(agentId, 100, "tUSD8 service payment settled");
            reputation.giveFeedback(merchantId, 100, "tUSD8 service payment received");
        }
    }
}
