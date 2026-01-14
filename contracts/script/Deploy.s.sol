// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AIOracle} from "../src/AIOracle.sol";
import {DisputeManager} from "../src/DisputeManager.sol";
import {PredictionMarket} from "../src/PredictionMarket.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Derive signer address from the private key (same as deployer)
        address signer = vm.addr(deployerPrivateKey);
        console.log("Using signer address:", signer);

        // 1. Deploy AIOracle with the signer address
        AIOracle oracle = new AIOracle(signer);
        console.log("AIOracle deployed at:", address(oracle));

        // 2. Deploy DisputeManager
        DisputeManager disputeManager = new DisputeManager(address(oracle));
        console.log("DisputeManager deployed at:", address(disputeManager));

        // 3. Set DisputeManager on Oracle
        oracle.setDisputeManager(address(disputeManager));

        // 4. Deploy PredictionMarket
        PredictionMarket market = new PredictionMarket(address(oracle), address(disputeManager));
        console.log("PredictionMarket deployed at:", address(market));

        vm.stopBroadcast();

        // Print addresses for verification
        console.log("=== Contract Addresses for Verification ===");
        console.log("ORACLE_ADDRESS=", address(oracle));
        console.log("DISPUTE_MANAGER_ADDRESS=", address(disputeManager));
        console.log("MARKET_ADDRESS=", address(market));
        console.log("ORACLE_SIGNER=", signer);
        console.log("");
        console.log("To verify contracts, run: ./verify.sh <ORACLE_ADDRESS> <DISPUTE_MANAGER_ADDRESS> <MARKET_ADDRESS> <ORACLE_SIGNER>");
    }
}
