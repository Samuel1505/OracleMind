// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AIOracle.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract AIOracleTest is Test {
    using ECDSA for bytes32;

    AIOracle public oracle;
    uint256 internal signerPrivateKey;
    address internal signer;

    function setUp() public {
        signerPrivateKey = 0xA11CE;
        signer = vm.addr(signerPrivateKey);
        oracle = new AIOracle(signer);
    }

    function test_SubmitVerdictWithValidSignature() public {
        bytes32 marketId = keccak256("market1");
        bool outcome = true;
        uint256 confidence = 95;
        string[] memory sources = new string[](1);
        sources[0] = "https://example.com";

        // Generate signature
        bytes32 dataHash = keccak256(abi.encodePacked(marketId, outcome, confidence));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(dataHash);
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Submit verdict
        oracle.submitVerdict(marketId, outcome, confidence, sources, signature);

        // Verify state
        (bool storedOutcome, uint256 storedConfidence, uint256 storedTimestamp) = oracle.getVerdict(marketId);
        assertTrue(storedOutcome == outcome);
        assertEq(storedConfidence, confidence);
        assertGt(storedTimestamp, 0);
    }

    function test_RevertIfSignatureInvalid() public {
        bytes32 marketId = keccak256("market2");
        bool outcome = false;
        uint256 confidence = 10;
        string[] memory sources = new string[](0);

        // Generate INVALID signature (signed by random key)
        uint256 randomKey = 0xB0B;
        bytes32 dataHash = keccak256(abi.encodePacked(marketId, outcome, confidence));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(dataHash);
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(randomKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Expect revert
        vm.expectRevert("Invalid signature");
        oracle.submitVerdict(marketId, outcome, confidence, sources, signature);
    }
    
    function test_RevertIfDuplicateVerdict() public {
         bytes32 marketId = keccak256("market1");
        bool outcome = true;
        uint256 confidence = 95;
        string[] memory sources = new string[](1);
        sources[0] = "https://example.com";

        // Generate signature
        bytes32 dataHash = keccak256(abi.encodePacked(marketId, outcome, confidence));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(dataHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        oracle.submitVerdict(marketId, outcome, confidence, sources, signature);
        
        // Try again
        vm.expectRevert("Verdict already exists");
        oracle.submitVerdict(marketId, outcome, confidence, sources, signature);
    }
}
