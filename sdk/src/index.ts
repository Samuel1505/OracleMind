import { ethers } from "ethers";

export interface OracleMindConfig {
    rpcUrl?: string; // Optional if using browser provider
    oracleAddress: string;
    aiServiceUrl?: string; // URL of the off-chain AI agent API
}

export interface ResolutionRequest {
    marketId: string;
    question: string;
    sources: string[];
}

export class OracleMindSDK {
    private provider: ethers.Provider;
    private oracleContract: ethers.Contract;
    private aiServiceUrl: string;

    constructor(config: OracleMindConfig, provider?: ethers.Provider) {
        this.provider = provider || new ethers.JsonRpcProvider(config.rpcUrl);
        this.aiServiceUrl = config.aiServiceUrl || "http://localhost:8000";
        
        const oracleAbi = [
            "function getVerdict(bytes32 marketId) view returns (bool, uint256)",
            "function hasVerdict(bytes32 marketId) view returns (bool)"
        ];
        
        this.oracleContract = new ethers.Contract(config.oracleAddress, oracleAbi, this.provider);
    }

    /**
     * Triggers the AI resolution process for a market.
     * This calls the Oracle Node (off-chain) to analyze and submit the verdict.
     * @param marketId The ID of the market to resolve
     */
    async resolveMarket(marketId: string): Promise<any> {
        // 1. Get market details from chain (mock or real)
        // const market = await this.predictionMarket.markets(marketId);
        // const question = market.question;
        
        // For Hackathon MVP, we might pass question/sources explicitly 
        // or let the Oracle fetch them from chain.
        // Let's let the AI agents find their own sources using NewsAPI and web search
        const question = "Will Nigeria win against Morocco in today's match?"; 
        const sources: string[] = []; // Empty - let AI agents use NewsAPI and web search

        try {
            console.log(`SDK: Requesting resolution for ${marketId}...`);
            const response = await fetch("http://localhost:3000/resolve-and-submit", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    marketId,
                    question, // In prod, Oracle Node fetches this from Contract
                    sources
                })
            });
            
            if (!response.ok) {
                throw new Error(`Oracle Service Error: ${response.statusText}`);
            }

            const data = await response.json();
            console.log("SDK: Resolution initiated successfully", data);
            return data;
        
        } catch (error) {
            console.error("SDK Error:", error);
            throw error;
        }
    }

    /**
     * Checks if a market has been resolved on-chain.
     */
    async isResolved(marketId: string): Promise<boolean> {
        return await this.oracleContract.hasVerdict(marketId);
    }

    /**
     * Gets the final resolved outcome if available.
     */
    async getOutcome(marketId: string): Promise<{ outcome: boolean, confidence: number } | null> {
        const isResolved = await this.isResolved(marketId);
        if (!isResolved) return null;

        const [outcome, confidence] = await this.oracleContract.getVerdict(marketId);
        return { outcome, confidence: Number(confidence) };
    }
    
    /**
     * Gets a preliminary AI signal (predictive, not final).
     */
    async getAISignal(marketId: string): Promise<{ probability: number, confidence: string }> {
         // Mock return
        return { probability: 0.75, confidence: "high" };
    }
}
