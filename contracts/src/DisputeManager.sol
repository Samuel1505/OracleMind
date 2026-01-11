// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AIOracle.sol";

/// @title DisputeManager
/// @notice Handles disputes for optimistic verdicts
contract DisputeManager {
    AIOracle public oracle;
    uint256 public disputeWindow = 1 days;

    enum DisputeStatus { None, Active, ResolvedReverted, ResolvedConfirmed }

    struct Dispute {
        address challenger;
        uint256 timestamp;
        DisputeStatus status;
    }

    mapping(bytes32 => Dispute) public disputes;

    event DisputeRaised(bytes32 indexed marketId, address indexed challenger);
    event DisputeResolved(bytes32 indexed marketId, DisputeStatus status);

    constructor(address _oracle) {
        oracle = AIOracle(_oracle);
    }

    /// @notice Raise a dispute against a verdict
    /// @dev Requires bond (TODO)
    function disputeVerdict(bytes32 marketId) external payable {
        // 1. Check if verdict exists and get details
        (,, uint256 vTimestamp) = oracle.getVerdict(marketId); 
        
        // 2. Check if within dispute window
        require(block.timestamp <= vTimestamp + disputeWindow, "Dispute window closed");

        // 3. Create dispute
        require(disputes[marketId].status == DisputeStatus.None, "Already disputed");
        
        disputes[marketId] = Dispute({
            challenger: msg.sender,
            timestamp: block.timestamp,
            status: DisputeStatus.Active
        });

        emit DisputeRaised(marketId, msg.sender);
    }

    /// @notice Check if a market is currently disputed
    function isDisputed(bytes32 marketId) external view returns (bool) {
        return disputes[marketId].status == DisputeStatus.Active;
    }
}
