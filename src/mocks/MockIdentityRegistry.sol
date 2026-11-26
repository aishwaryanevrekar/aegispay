// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IIdentityRegistry} from "../interfaces/IAevum.sol";

/// @notice Testnet adapter for the ERC-8004 Identity Registry.
/// @dev Registers an "agent card" (a tokenURI describing capabilities) and binds
///      one runtime address that is authorized to act for that agent identity.
contract MockIdentityRegistry is IIdentityRegistry {
    uint256 public nextId = 1;

    mapping(uint256 => address) private _owner;
    mapping(uint256 => address) private _agentAddress;
    mapping(uint256 => string) private _tokenURI;
    mapping(address => uint256) public latestIdOf;

    event Registered(uint256 indexed agentId, address indexed owner, address indexed agent, string tokenURI);
    event AgentAddressUpdated(uint256 indexed agentId, address indexed agent);

    error NotOwner();
    error ZeroAddress();
    error UnknownAgent();

    function register(string calldata tokenURI_) external returns (uint256 agentId) {
        agentId = nextId++;
        latestIdOf[msg.sender] = agentId;
        _owner[agentId] = msg.sender;
        _tokenURI[agentId] = tokenURI_;
        emit Registered(agentId, msg.sender, address(0), tokenURI_);
    }

    /// @notice Principal binds (or rotates) the key that the agent runs with.
    function setAgentAddress(uint256 agentId, address agent) external {
        if (_owner[agentId] == address(0)) revert UnknownAgent();
        if (msg.sender != _owner[agentId]) revert NotOwner();
        if (agent == address(0)) revert ZeroAddress();
        _agentAddress[agentId] = agent;
        emit AgentAddressUpdated(agentId, agent);
    }

    function ownerOf(uint256 agentId) external view returns (address) {
        address owner = _owner[agentId];
        if (owner == address(0)) revert UnknownAgent();
        return owner;
    }

    function authorizedAddress(uint256 agentId) external view returns (address) {
        return _agentAddress[agentId];
    }

    function tokenURI(uint256 agentId) external view returns (string memory) {
        return _tokenURI[agentId];
    }

    function isAuthorized(uint256 agentId, address candidate) external view returns (bool) {
        return candidate != address(0) && candidate == _agentAddress[agentId];
    }
}
