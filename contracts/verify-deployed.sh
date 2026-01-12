#!/bin/bash
# Verification script for deployed contracts
# Run this when network connectivity is available

set -e

source .env

# Contract addresses from deployment
ORACLE_ADDRESS="0xA6c15eDC8ceffb558A54ead5bd9d833A589276bC"
DISPUTE_MANAGER_ADDRESS="0xF396F264b10EbB39D444ABB9677059B5AF48f334"
MARKET_ADDRESS="0x62e325C4aaB5f3808DCAaFb71d932f4E97455368"
ORACLE_SIGNER="0x0000000000000000000000000000000000000000"

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "Error: ETHERSCAN_API_KEY not set in .env file"
    exit 1
fi

echo "Verifying contracts on Mantle Sepolia..."
echo "Oracle: $ORACLE_ADDRESS"
echo "DisputeManager: $DISPUTE_MANAGER_ADDRESS"
echo "Market: $MARKET_ADDRESS"
echo ""

# Verify AIOracle
echo "Verifying AIOracle..."
forge verify-contract \
    $ORACLE_ADDRESS \
    src/AIOracle.sol:AIOracle \
    --chain mantle-sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" $ORACLE_SIGNER) \
    --compiler-version 0.8.30 \
    --watch || echo "AIOracle verification failed or already verified"

# Verify DisputeManager
echo "Verifying DisputeManager..."
forge verify-contract \
    $DISPUTE_MANAGER_ADDRESS \
    src/DisputeManager.sol:DisputeManager \
    --chain mantle-sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" $ORACLE_ADDRESS) \
    --compiler-version 0.8.30 \
    --watch || echo "DisputeManager verification failed or already verified"

# Verify PredictionMarket
echo "Verifying PredictionMarket..."
forge verify-contract \
    $MARKET_ADDRESS \
    src/PredictionMarket.sol:PredictionMarket \
    --chain mantle-sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address,address)" $ORACLE_ADDRESS $DISPUTE_MANAGER_ADDRESS) \
    --compiler-version 0.8.30 \
    --watch || echo "PredictionMarket verification failed or already verified"

echo ""
echo "Verification complete!"
