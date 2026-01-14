import { createWalletClient, createPublicClient, http, parseAbi, keccak256, encodePacked, toHex, Hex } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

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
    private account: ReturnType<typeof privateKeyToAccount>;
    private walletClient: ReturnType<typeof createWalletClient>;
    private publicClient: ReturnType<typeof createPublicClient>;
    private oracleAddress: Hex;

    constructor(config: OracleConfig) {
        // Ensure private key has 0x prefix (viem requirement)
        const privateKey = config.privateKey.startsWith('0x') 
            ? config.privateKey 
            : `0x${config.privateKey}`;
        
        // Create account from private key
        this.account = privateKeyToAccount(privateKey as Hex);
        
        // Create wallet client for writing (using custom RPC, not hardcoded chain)
        this.walletClient = createWalletClient({
            account: this.account,
            transport: http(config.rpcUrl)
        });

        // Create public client for reading
        this.publicClient = createPublicClient({
            transport: http(config.rpcUrl)
        });

        this.oracleAddress = config.oracleAddress as Hex;
    }

    async submitVerdict(marketId: string, outcome: boolean, confidence: number, sources: string[]) {
        try {
            console.log(`Submitting verdict for ${marketId}: Outcome=${outcome}, Confidence=${confidence}`);

            // 1. Create the hash to match Solidity's keccak256(abi.encodePacked(...))
            const messageHash = keccak256(
                encodePacked(
                    ['bytes32', 'bool', 'uint256'],
                    [marketId as Hex, outcome, BigInt(confidence)]
                )
            );

            // 2. Sign the message hash
            // viem's signMessage automatically adds the "\x19Ethereum Signed Message:\n32" prefix
            const signature = await this.walletClient.signMessage({
                message: { raw: messageHash }
            });
            
            console.log("Generated Signature:", signature);

            // 3. Submit to contract
            const abi = parseAbi([
                'function submitVerdict(bytes32 marketId, bool outcome, uint256 confidence, string[] sources, bytes signature)'
            ]);

            const hash = await this.walletClient.writeContract({
                address: this.oracleAddress,
                abi,
                functionName: 'submitVerdict',
                args: [marketId as Hex, outcome, BigInt(confidence), sources, signature]
            });
            
            console.log(`Verdict submitted! Tx Hash: ${hash}`);
            
            // Wait for transaction confirmation
            const receipt = await this.publicClient.waitForTransactionReceipt({ hash });
            console.log("Transaction confirmed.");
            
            return { hash, ...receipt };
            
        } catch (error) {
            console.error("Error submitting verdict:", error);
            throw error;
        }
    }
}
