// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AegisAccount} from "./AegisAccount.sol";

/// @title AegisFactory
/// @notice Deterministic one-account-per-principal deployer so integrators can
///         discover a user's account with a single view call.
contract AegisFactory {
    address public immutable token;
    address public immutable identity;
    address public immutable reputation;
    address public immutable router;

    mapping(address => address) public accountOf;

    event AccountCreated(address indexed owner, address indexed account);

    error ZeroAddress();

    constructor(address token_, address identity_, address reputation_, address router_) {
        if (token_ == address(0) || identity_ == address(0) || router_ == address(0)) revert ZeroAddress();
        token = token_;
        identity = identity_;
        reputation = reputation_;
        router = router_;
    }

    function createAccount() external returns (address account) {
        account = accountOf[msg.sender];
        if (account != address(0)) return account;

        account = address(new AegisAccount(msg.sender, token, identity, reputation, router));
        accountOf[msg.sender] = account;
        emit AccountCreated(msg.sender, account);
    }
}
