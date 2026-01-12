# Contract Verification Status

## ✅ Contracts Deployed Successfully

All contracts have been deployed to Mantle Sepolia:

- **AIOracle**: `0xA6c15eDC8ceffb558A54ead5bd9d833A589276bC`
- **DisputeManager**: `0xF396F264b10EbB39D444ABB9677059B5AF48f334`
- **PredictionMarket**: `0x62e325C4aaB5f3808DCAaFb71d932f4E97455368`

## ⚠️ Verification Status

Verification failed due to network connectivity issues (cannot reach `binaries.soliditylang.org`). However, contracts are deployed and functional.

## 🔧 How to Verify (When Network is Available)

### Option 1: Use the Automated Script

```bash
cd contracts
source .env
./verify-deployed.sh
```

### Option 2: Manual Verification Commands

Make sure `ETHERSCAN_API_KEY` is set in your `.env` file, then run:

**Verify AIOracle:**
```bash
source .env
forge verify-contract \
    0xA6c15eDC8ceffb558A54ead5bd9d833A589276bC \
    src/AIOracle.sol:AIOracle \
    --chain mantle-sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" 0x0000000000000000000000000000000000000000) \
    --compiler-version 0.8.30 \
    --watch
```

**Verify DisputeManager:**
```bash
forge verify-contract \
    0xF396F264b10EbB39D444ABB9677059B5AF48f334 \
    src/DisputeManager.sol:DisputeManager \
    --chain mantle-sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" 0xA6c15eDC8ceffb558A54ead5bd9d833A589276bC) \
    --compiler-version 0.8.30 \
    --watch
```

**Verify PredictionMarket:**
```bash
forge verify-contract \
    0x62e325C4aaB5f3808DCAaFb71d932f4E97455368 \
    src/PredictionMarket.sol:PredictionMarket \
    --chain mantle-sepolia \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address,address)" 0xA6c15eDC8ceffb558A54ead5bd9d833A589276bC 0xF396F264b10EbB39D444ABB9677059B5AF48f334) \
    --compiler-version 0.8.30 \
    --watch
```

### Option 3: Manual Verification via Block Explorer

1. Visit: https://explorer.sepolia.mantle.xyz
2. Search for each contract address
3. Click "Verify and Publish" on the contract page
4. Upload the source files and provide constructor arguments:
   - **AIOracle**: Constructor arg: `0x0000000000000000000000000000000000000000`
   - **DisputeManager**: Constructor arg: `0xA6c15eDC8ceffb558A54ead5bd9d833A589276bC`
   - **PredictionMarket**: Constructor args: `0xA6c15eDC8ceffb558A54ead5bd9d833A589276bC`, `0xF396F264b10EbB39D444ABB9677059B5AF48f334`

## 📝 Notes

- The network connectivity issue prevents Foundry from downloading compiler metadata
- Contracts are fully functional even without verification
- Verification can be done later when network connectivity is restored
- The `verify-deployed.sh` script contains all the correct addresses and can be run anytime

## 🔍 View Contracts on Explorer

- AIOracle: https://explorer.sepolia.mantle.xyz/address/0xA6c15eDC8ceffb558A54ead5bd9d833A589276bC
- DisputeManager: https://explorer.sepolia.mantle.xyz/address/0xF396F264b10EbB39D444ABB9677059B5AF48f334
- PredictionMarket: https://explorer.sepolia.mantle.xyz/address/0x62e325C4aaB5f3808DCAaFb71d932f4E97455368
