# Technical Specification: LockedFI Smart Vault

**Version:** 1.0.0  
**Status:** Prototype/Research  
**Date:** March 8, 2026  
**Subject:** AI-Augmented Decentralized Asset Management with Zero-Knowledge Verification

---

## 1. Executive Summary
LockedFI is a decentralized asset management protocol designed to mitigate risk in high-value transactions without compromising user privacy. By integrating Account Abstraction (ERC-4337), Large Language Model (LLM) reasoning, and ZK-SNARKs, LockedFI provides a "Proof-of-Safety" layer for the Ethereum ecosystem.

## 2. Problem Statement
Traditional hardware wallets provide "cold" security but lack contextual awareness. Smart contract wallets offer programmability but often require complex, manual rule-setting. LockedFI addresses these gaps by introducing:
1. **Contextual Security**: AI-driven transaction analysis.
2. **Privacy-Preserving Compliance**: ZK-verified financial status.
3. **Programmable Risk Mitigants**: Automated threshold enforcement.

## 3. System Architecture

### 3.1 On-Chain Layer (Ethereum/EVM)
The core of the system is the `SmartVault.sol` contract, which acts as a programmable account.
- **Access Control**: Implements a multi-signature validation logic where `signature_length == 130` (65 bytes Owner + 65 bytes AI).
- **Verification Engine**: Interfaces with `IVerifier` to validate Groth16 proofs.
- **Risk Engine**: Enforces a `RISK_LIMIT` (default 0.1 ETH). Transactions exceeding this limit trigger mandatory ZK-Badge checks and AI co-signing.

### 3.2 Intelligence Layer (AI Guardian)
A Python-based middleware service utilizing the Groq inference engine.
- **Model**: Llama-3.3-70b-versatile.
- **Objective**: Analyze the semantic intent of a transaction (e.g., "Withdraw 5 ETH to unknown address") against the user's historical patterns and badge status.
- **Action**: Outputs a deterministic `APPROVE` or `REJECT` decision followed by a cryptographic signature on success.

### 3.3 Privacy Layer (Zero-Knowledge)
A ZK-SNARK circuit built with Circom.
- **Public Inputs**: Verification keys and result status.
- **Private Inputs**: User's raw financial data (income/balance).
- **Result**: Generates a proof that the user meets the "High-Income" threshold without disclosing the actual balance.

## 4. Operational Workflows

### 4.1 Transaction Lifecycle
1. **Initialization**: User requests a transaction via the Frontend.
2. **Local Signing**: User's private key signs the `UserOperation` hash.
3. **AI Interception**: The Next.js API route forwards the hash and context to the AI Guardian.
4. **Contextual Analysis**: AI evaluates risk and co-signs if safe.
5. **On-Chain Validation**: `SmartVault` verifies both signatures and checks the `hasHighIncomeBadge` mapping.
6. **Execution**: If all conditions pass, the transaction is executed.

## 5. Security Model
- **Trust Assumption**: The AI Guardian is a trusted co-signer in this prototype. Future iterations will explore Decentralized AI (DeAI) or TEE-based (Trusted Execution Environment) signing.
- **Encryption**: All communication between the frontend and the AI service is conducted via HTTPS.
- **Failure Modes**: If the AI service is offline, the vault defaults to a restricted state where only low-value transactions are permitted.

## 6. Technical Requirements
- **Runtime**: Node.js v20.x, Python 3.11+.
- **Blockchain**: EVM-compatible chain (Anvil for local development).
- **Tooling**: Foundry (Forge/Cast), SnarkJS, Circom.

## 7. Roadmap
- **Phase 1**: Prototype development (Current).
- **Phase 2**: Multi-agent consensus for the Guardian layer.
- **Phase 3**: Dynamic risk limits based on on-chain volatility.
- **Phase 4**: Mainnet-ready security audit and KMS integration.
