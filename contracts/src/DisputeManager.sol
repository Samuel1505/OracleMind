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
    function disputeVerdict(bytes32 marketId) external payable { // payable for bond
        // 1. Check if verdict exists
        (bool exists,) = oracle.getVerdict(marketId); 
        // Note: getVerdict throws if doesn't exist, we might want a safer check or try/catch effectively
        // For MVP assuming it exists if calling this.
        
        // 2. Check if within dispute window (would need verdict timestamp from oracle)
        // Assuming open for now.

        // 3. Create dispute
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
