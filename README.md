# LockedFI: The AI-Guarded ZK-Smart Vault 🧐🛡️🚀

[![Stack: Solidity](https://img.shields.io/badge/Solidity-0.8.19-363636?logo=solidity)](https://soliditylang.org/)
[![Stack: Next.js](https://img.shields.io/badge/Next.js-15-black?logo=next.js)](https://nextjs.org/)
[![AI: Groq](https://img.shields.io/badge/AI-Groq%20Llama%203-orange)](https://groq.com/)

**LockedFI** is a sophisticated decentralized asset management prototype that bridges the gap between **Account Abstraction (ERC-4337)**, **Zero-Knowledge Proofs (Groth16)**, and **Real-time AI Risk Analysis**. It introduces a "Context-Aware" security layer to DeFi, ensuring that high-value transactions are not only cryptographically signed but also semantically verified.

---

## 🌟 Key Features

*   **🤖 AI Guardian Co-Signing**: A specialized Llama-3-powered agent that analyzes transaction intent and co-signs safe operations.
*   **🔐 ZK-Income Verification**: Privacy-preserving "High-Income" badges that unlock higher withdrawal limits without exposing your net worth.
*   **💳 Account Abstraction Core**: Built as a programmable smart contract account (SmartVault), moving beyond simple EOAs.
*   **⚡ Dual-Signature Validation**: Transactions above a certain threshold (`0.1 ETH`) require cryptographic approval from both the Owner and the AI Guard.
*   **🎨 Modern Dashboard**: A high-performance Next.js 15 frontend with real-time status tracking and interactive signing flows.

---

## 🏗️ System Architecture

LockedFI operates as a three-tier security sandwich:

1.  **The Privacy Layer (ZK)**: Uses Circom to generate ZK-SNARKs. A user proves they have a certain income level locally; only the proof is sent to `SmartVault.sol` to toggle the `hasHighIncomeBadge` flag.
2.  **The Intelligence Layer (AI)**: A middleware service that consumes the Groq SDK. It performs semantic analysis on withdrawal requests, verifying they align with safe parameters before providing a secondary signature.
3.  **The Execution Layer (EVM)**: The `SmartVault` contract enforces the logic. It checks signature lengths, validates ZK proofs, and handles the atomic transfer of funds.

---

## 🛠️ Tech Stack

| Category | Technology |
| :--- | :--- |
| **Blockchain** | Solidity, Foundry (Anvil, Forge, Cast) |
| **ZK-SNARKs** | Circom, SnarkJS (Groth16, BN128) |
| **AI/LLM** | Groq SDK, Llama-3.3-70b-versatile |
| **Frontend** | Next.js 15, TypeScript, TailwindCSS v4, Ethers.js v6 |
| **Backend** | Node.js (Next.js API Routes), Python (AI Guardian Service) |

---

## 🚀 Getting Started

### Prerequisites
*   **Foundry**: `curl -L https://foundry.paradigm.xyz | bash`
*   **Node.js**: v18 or newer
*   **Python**: v3.10+
*   **Groq API Key**: Obtain from [Groq Console](https://console.groq.com/)

### ⚡ Unified Launch
LockedFI is designed for a seamless, "one-command" setup experience.

```bash
# Clone the repository and navigate to the root
cd LockedFI

# Launch the entire stack (Blockchain, AI Service, and Dashboard)
chmod +x start.sh
./start.sh
```
The script will automatically check for dependencies, install necessary packages, deploy the smart contracts, and launch the user dashboard at `http://localhost:3000`.

---

## 📋 Operational Workflow

1.  **Connect**: Link your wallet to the LockedFI Dashboard.
2.  **Verify**: Generate a ZK-Proof to earn your "High-Income Badge" (stored on-chain).
3.  **Initiate**: Request a withdrawal.
4.  **Sign**: Sign the transaction locally (First Signature).
5.  **Audit**: The AI Guardian reviews the transaction context and co-signs (Second Signature).
6.  **Execute**: The `SmartVault` validates the dual-signature bundle and releases the funds.

---

## 🔒 Security & Privacy Notice

*   **Privacy**: Your raw income data never leaves your browser. LockedFI only ever sees the ZK-Proof.
*   **Security**: This is a **technical prototype**. For production use, the AI Guardian should be hosted in a Trusted Execution Environment (TEE), and private keys should be managed via a hardware-backed HSM/KMS.
*   **Limits**: The current `RISK_LIMIT` is set to `0.1 ETH` for demonstration purposes.

---
