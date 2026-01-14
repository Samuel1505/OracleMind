import { OracleMindSDK } from '../sdk/src/index';

// Real Config (Mantle Sepolia)
const config = {
    rpcUrl: "https://rpc.sepolia.mantle.xyz",
    oracleAddress: "0x62fca1b87606b8c30e7198d6e9bcb214833a8ea0", // NEW PredictionMarket address
    apiKey: "test-api-key"
};

async function main() {
    console.log("🚀 Starting OracleMind E2E Demo...");
    
    const sdk = new OracleMindSDK(config);
    // New unique marketId for Nigeria vs Morocco prediction
    const marketId = "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"; 

    console.log("\n1. User requests market resolution...");
    try {
        const result = await sdk.resolveMarket(marketId);
        console.log("\n✅ Demo Success! Result:", result);
    } catch (e) {
        console.error("\n❌ Demo Failed:", e);
    }
}

main();
