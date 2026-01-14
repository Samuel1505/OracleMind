import express from 'express';
import bodyParser from 'body-parser';
import { OracleSubmitter, OracleConfig } from './submitter';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
app.use(bodyParser.json());

const PORT = process.env.PORT || 3000;

// Config
const config: OracleConfig = {
    rpcUrl: process.env.RPC_URL || "http://127.0.0.1:8545",
    privateKey: process.env.PRIVATE_KEY || "",
    oracleAddress: process.env.ORACLE_CONTRACT_ADDRESS || ""
};

const submitter = new OracleSubmitter(config);

// Mock function to call Python API (in a real app, use axios/fetch)
// We'll use native fetch if Node 18+ or install node-fetch.
// For now, assuming fetch is available.
async function fetchAIAnalysis(question: string, sources: string[]): Promise<any> {
    const response = await fetch("http://localhost:8000/resolve", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ marketId: "pending", question, sources })
    });
    return await response.json();
}

app.post('/resolve-and-submit', async (req, res) => {
    const { marketId, question, sources } = req.body;
    
    if (!marketId || !question) {
        return res.status(400).json({ error: "Missing marketId or question" });
    }

    try {
        console.log(`Processing resolution for ${marketId}...`);
        
        // 1. Get AI Verdict
        const aiVerdict = await fetchAIAnalysis(question, sources || []);
        console.log("AI Verdict Received:", aiVerdict);
        
        if (!aiVerdict.outcome && aiVerdict.marketId === 'error') {
             return res.status(500).json({ error: "AI failed to resolve" });
        }

        // 2. Sign and Submit
        // Ensure confidence is number
        const confidence = typeof aiVerdict.confidence === 'number' ? aiVerdict.confidence : 0;
        
        const receipt = await submitter.submitVerdict(
            marketId,
            aiVerdict.outcome,
            Math.floor(confidence * 100), // Scale to 0-100 integer if needed, or keep raw if contract expects 0-100
            // Contract expects uint256 confidence. In implementation plan we didn't specify scale.
            // Let's assume contract expects basis points or similar? 
            // In AIOracle.sol, it's just uint256. 
            // If AI returns 0.95, treating as 95 is good logic.
            aiVerdict.sources
        );

        res.json({ 
            status: "success", 
            txHash: receipt.hash,
            verdict: aiVerdict 
        });
        
    } catch (error: any) {
        console.error('Error processing request:', error);
        res.status(500).json({ error: error.toString() });
    }
});

app.listen(PORT, () => {
    console.log(`Oracle Node running on port ${PORT}`);
});
