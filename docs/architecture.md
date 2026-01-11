# OracleMind Architecture

## Overview
OracleMind bridges off-chain AI reasoning with on-chain optimistic settlement.

## Core Components

### 1. Off-Chain AI Layer (`/ai`)
- **Agents (Python)**: Specialized agents (Sentiment, Event, Fact-Check) that consume external APIs.
- **Verdict Engine**: Aggregates agent outputs into a unified JSON verdict with a confidence score.
- **Schema**: Enforced JSON structure for all verdicts to ensure determinism.

### 2. Verification & Submission Layer (`/oracle`)
- **Oracle Service (TypeScript)**: Listens for resolution requests or runs on a schedule.
- **Signing**: Signs the AI verdict using a known oracle key.
- **On-chain Submission**: Pushes the signed verdict + CID (if IPFS used) to the smart contract.

### 3. On-Chain Contracts (`/contracts`)
- **Optimistic Oracle**: Accepts signed verdicts; holds them for a challenge period (e.g., 24h).
- **Dispute Mechanism**: Allows any bonded user to challenge a verdict.
- **Market Integration**: Callbacks to prediction markets upon finalization.

### 4. Developer SDK (`/sdk`)
- **Purpose**: Simplifies fetching AI signals and resolving markets for dApp builders.
