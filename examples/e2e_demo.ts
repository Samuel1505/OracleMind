import { OracleMindSDK } from '../sdk/src/index';

// Mock Config
const config = {
    rpcUrl: "http://localhost:8545",
    oracleAddress: "0x5FbDB2315678afecb367f032d93F642f64180aa3", // Default Foundry deploy address
    apiKey: "test-api-key"
};

async function main() {
    console.log("🚀 Starting OracleMind E2E Demo...");
    
    const sdk = new OracleMindSDK(config);
    const marketId = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"; // Mock ID

    console.log("\n1. User requests market resolution...");
    try {
        const result = await sdk.resolveMarket(marketId);
        console.log("\n✅ Demo Success! Result:", result);
    } catch (e) {
        console.error("\n❌ Demo Failed:", e);
    }
}

main();
