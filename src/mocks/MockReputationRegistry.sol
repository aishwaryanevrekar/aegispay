// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IReputationRegistry} from "../interfaces/IAevum.sol";

/// @notice Testnet adapter for the ERC-8004 Reputation Registry.
/// @dev Each successful settlement appends a signed feedback entry, producing a
///      verifiable on-chain audit trail of agent behaviour.
contract MockReputationRegistry is IReputationRegistry {
    struct Feedback {
        address giver;
        uint8 score;
        string comment;
        uint256 timestamp;
    }

    mapping(uint256 => Feedback[]) private _feedback;

    event FeedbackGiven(uint256 indexed agentId, address indexed giver, uint8 score, string comment);

    error InvalidScore();

    function giveFeedback(uint256 agentId, uint8 score, string calldata comment) external {
        if (score > 100) revert InvalidScore();
        _feedback[agentId].push(Feedback(msg.sender, score, comment, block.timestamp));
        emit FeedbackGiven(agentId, msg.sender, score, comment);
    }

    function getSummary(uint256 agentId) external view returns (uint256 count, uint256 totalScore) {
        Feedback[] storage entries = _feedback[agentId];
        count = entries.length;
        for (uint256 i = 0; i < count; ++i) {
            totalScore += entries[i].score;
        }
    }

    function getFeedback(uint256 agentId, uint256 index) external view returns (Feedback memory) {
        return _feedback[agentId][index];
    }

    function feedbackCount(uint256 agentId) external view returns (uint256) {
        return _feedback[agentId].length;
    }
}
