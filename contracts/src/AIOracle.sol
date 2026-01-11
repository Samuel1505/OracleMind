// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title AIOracle
/// @notice Optimistic oracle that verifies AI-signed verdicts
contract AIOracle {
    using ECDSA for bytes32;

    struct Verdict {
        bytes32 marketId;
        bool outcome;
        uint256 confidence;
        uint256 timestamp;
        string[] sources;
    }

    // Mapping from marketId to Verdict
    mapping(bytes32 => Verdict) public verdicts;
    // Mapping to check if a verdict exists
    mapping(bytes32 => bool) public hasVerdict;

    address public disputeManager;
    address public signer; // The authorized AI agent/signer address

    event VerdictSubmitted(bytes32 indexed marketId, bool outcome, uint256 confidence);
    event DisputeManagerUpdated(address indexed newManager);
    event SignerUpdated(address indexed newSigner);

    constructor(address _signer) {
        signer = _signer;
    }

    modifier onlyDisputeManager() {
        require(msg.sender == disputeManager, "Only DisputeManager");
        _;
    }

    function setDisputeManager(address _disputeManager) external {
        // In a real system, this should be owned
        disputeManager = _disputeManager;
        emit DisputeManagerUpdated(_disputeManager);
    }

    /// @notice Submits a verdict signed by the AI agent
    /// @dev Verifies signature and signature content
    function submitVerdict(
        bytes32 marketId,
        bool outcome,
        uint256 confidence,
        string[] calldata sources,
        bytes calldata signature
    ) external {
        require(!hasVerdict[marketId], "Verdict already exists");

        // Recreate the message hash that was signed off-chain
        bytes32 dataHash = keccak256(abi.encodePacked(marketId, outcome, confidence));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(dataHash);
        
        // Recover the signer
        address recovered = ECDSA.recover(ethSignedMessageHash, signature);
        require(recovered == signer, "Invalid signature");

        verdicts[marketId] = Verdict({
            marketId: marketId,
            outcome: outcome,
            confidence: confidence,
            timestamp: block.timestamp,
            sources: sources
        });
        hasVerdict[marketId] = true;
        
        emit VerdictSubmitted(marketId, outcome, confidence);
    }

    /// @notice Helper to get verdict details
    function getVerdict(bytes32 marketId) external view returns (bool, uint256, uint256) {
        require(hasVerdict[marketId], "No verdict");
        Verdict memory v = verdicts[marketId];
        return (v.outcome, v.confidence, v.timestamp);
    }
}
