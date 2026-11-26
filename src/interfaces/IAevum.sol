// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal ERC-20 surface used by AegisPay. tUSD8 uses 8 decimals.
interface IERC20Minimal {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/// @notice Minimal ERC-8004 Identity Registry surface (testnet adapter).
/// @dev The production ERC-8004 registry is an ERC-721 agent card. Here we keep
///      the authorization semantics: an agent identity is owned by a principal
///      and delegates operational authority to one runtime address.
interface IIdentityRegistry {
    function register(string calldata tokenURI) external returns (uint256 agentId);
    function ownerOf(uint256 agentId) external view returns (address);
    function authorizedAddress(uint256 agentId) external view returns (address);
    function isAuthorized(uint256 agentId, address candidate) external view returns (bool);
}

/// @notice Minimal ERC-8004 Reputation Registry surface (testnet adapter).
/// @dev Scores are 0..100 to keep the demo readable on chain.
interface IReputationRegistry {
    function giveFeedback(uint256 agentId, uint8 score, string calldata comment) external;
    function getSummary(uint256 agentId) external view returns (uint256 count, uint256 totalScore);
}

/// @notice Merchant settlement hook called by AegisAccount via `payWithService`.
interface IPaymentRouter {
    function settle(
        address account,
        address merchant,
        uint256 amount,
        bytes32 serviceRef,
        uint256 agentId
    ) external;
}
