# OracleMind
**AI-assisted oracle resolution for prediction markets**

OracleMind is an experimental system that combines off-chain AI agents with on-chain optimistic oracles to automate the resolution of prediction markets and provide AI-powered signals.

The goal is to make prediction markets easier to build, safer to resolve, and more expressive for real-world and ambiguous events.

## Why OracleMind?
Prediction markets often struggle with:
- Manual or centralized resolution
- Ambiguous real-world outcomes
- Trust in a single resolver

OracleMind explores a different approach:
- **AI agents** interpret off-chain data
- **Oracles** make those interpretations verifiable on-chain
- **Smart contracts** resolve markets automatically, with disputes as a safety net

## High-level idea
1. **Off-chain AI agents** analyze trusted data sources (news, APIs, reports)
2. The AI produces **structured verdicts** (not free-form text)
3. An **oracle layer** signs and submits the verdict on-chain
4. Prediction markets settle **optimistically**
5. **Disputes** can be raised if the verdict is incorrect

> "AI proposes. Oracles verify. Smart contracts execute."

## Repository structure
This repository is organized as a monorepo containing all major components:

- `contracts/`   → Smart contracts (oracle + prediction markets)
- `ai/`          → Python AI agents and verdict schemas
- `oracle/`      → TypeScript oracle submission & verification service
- `sdk/`         → Developer SDK for integrating OracleMind
- `docs/`        → Architecture and design notes
- `examples/`    → Minimal integration examples

Each component is designed to be modular and replaceable.

## Design principles
- **AI stays off-chain**: AI outputs are treated as inputs, not truth.
- **Structured over subjective**: AI produces machine-readable verdicts with confidence and sources.
- **Optimistic by default**: Assume correctness, allow disputes.
- **Developer-first**: Integration should take minutes, not weeks.

## Current status
🚧 **Early / active development**

- Core architecture is being defined
- Smart contracts and AI agents are under construction
- APIs and SDK interfaces may change

This project is being built iteratively.

## Non-goals (for now)
- No frontend UI
- No governance token
- No fully decentralized court system
- No multi-chain deployment

## Inspiration
OracleMind is inspired by:
- Optimistic oracles (e.g. UMA)
- Prediction markets
- AI agent systems
- Oracle networks such as Chainlink

---
## Disclaimer
This is experimental software. Do not use in production or with real funds.
