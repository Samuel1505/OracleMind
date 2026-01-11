// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AIOracle.sol";
import "./DisputeManager.sol";

/// @title PredictionMarket
/// @notice Market that resolves based on AIOracle verdicts
contract PredictionMarket {
    AIOracle public oracle;
    DisputeManager public disputeManager;

    struct Market {
        string question;
        bool resolved;
        bool outcome;
        uint256 endTime;
        uint256 totalYes;
        uint256 totalNo;
    }
    
    mapping(bytes32 => Market) public markets;
    // Track user bets: marketId -> user -> yes/no amount
    mapping(bytes32 => mapping(address => uint256)) public betsYes;
    mapping(bytes32 => mapping(address => uint256)) public betsNo;

    event MarketCreated(bytes32 indexed marketId, string question);
    event MarketResolved(bytes32 indexed marketId, bool outcome);

    constructor(address _oracle, address _disputeManager) {
        oracle = AIOracle(_oracle);
        disputeManager = DisputeManager(_disputeManager);
    }
    
    function createMarket(string memory question, uint256 duration) external returns (bytes32) {
        bytes32 marketId = keccak256(abi.encodePacked(question, block.timestamp, msg.sender));
        
        markets[marketId] = Market({
            question: question,
            resolved: false,
            outcome: false,
            endTime: block.timestamp + duration,
            totalYes: 0,
            totalNo: 0
        });
        
        emit MarketCreated(marketId, question);
        return marketId;
    }

    /// @notice Settles a market if oracle has a verdict and no active dispute
    function settle(bytes32 marketId) external {
        Market storage m = markets[marketId];
        require(!m.resolved, "Already resolved");
        
        // Check for dispute
        require(!disputeManager.isDisputed(marketId), "Market is disputed");

        // Get verdict
        (bool outcome, , ) = oracle.getVerdict(marketId);
        
        m.outcome = outcome;
        m.resolved = true;
        
        emit MarketResolved(marketId, outcome);
    }


}
