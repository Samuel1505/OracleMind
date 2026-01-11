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
        address signer = vm.envAddress("ORACLE_SIGNER");

        vm.startBroadcast(deployerPrivateKey);

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
    }
}
