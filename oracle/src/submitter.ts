import { ethers } from "ethers";
import * as fs from "fs";

// Configuration interface
export interface OracleConfig {
    rpcUrl: string;
    privateKey: string;
    oracleAddress: string;
}

interface Verdict {
    marketId: string;
    outcome: boolean;
    confidence: number;
    timestamp: number;
    sources: string[];
}

export class OracleSubmitter {
    private provider: ethers.JsonRpcProvider;
    private wallet: ethers.Wallet;
    private contract: ethers.Contract;

    constructor(config: OracleConfig) {
        this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
        this.wallet = new ethers.Wallet(config.privateKey, this.provider);
        
        const abi = [
            "function submitVerdict(bytes32 marketId, bool outcome, uint256 confidence, string[] sources, bytes signature)"
        ];
        
        this.contract = new ethers.Contract(config.oracleAddress, abi, this.wallet);
    }

    async submitVerdict(marketId: string, outcome: boolean, confidence: number, sources: string[]) {
        try {
            console.log(`Submitting verdict for ${marketId}: Outcome=${outcome}, Confidence=${confidence}`);

            // 1. Create the hash to match Solidity's keccak256(abi.encodePacked(...))
            // Solidity: keccak256(abi.encodePacked(marketId, outcome, confidence))
            const messageHash = ethers.solidityPackedKeccak256(
                ["bytes32", "bool", "uint256"],
                [marketId, outcome, confidence] // ensure marketId is bytes32 string
            );

            // 2. Sign the binary hash
            // This adds the "\x19Ethereum Signed Message:\n32" prefix
            // matching MessageHashUtils.toEthSignedMessageHash(dataHash)
            const signature = await this.wallet.signMessage(ethers.getBytes(messageHash));
            
            console.log("Generated Signature:", signature);

            // 3. Submit to contract
            const tx = await this.contract.submitVerdict(
                marketId,
                outcome,
                confidence,
                sources,
                signature
            );
            
            console.log(`Verdict submitted! Tx Hash: ${tx.hash}`);
            await tx.wait();
            console.log("Transaction confirmed.");
            return tx;
            
        } catch (error) {
            console.error("Error submitting verdict:", error);
            throw error;
        }
    }
}
