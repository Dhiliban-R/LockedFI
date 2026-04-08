# LockedFI: The AI-Guarded ZK-Smart Vault

[![Stack: Solidity](https://img.shields.io/badge/Solidity-0.8.19-363636?logo=solidity)](https://soliditylang.org/)
[![Stack: Next.js](https://img.shields.io/badge/Next.js-15-black?logo=next.js)](https://nextjs.org/)
[![AI: Groq](https://img.shields.io/badge/AI-Groq%20Llama%203-orange)](https://groq.com/)
[![ZK: Circom](https://img.shields.io/badge/ZK-Circom-blue)](https://docs.circom.io/)

**LockedFI** is a sophisticated decentralized asset management prototype that bridges the gap between **Account Abstraction (ERC-4337)**, **Zero-Knowledge Proofs (Groth16)**, and **Real-time AI Risk Analysis**. It introduces a "Context-Aware" security layer to DeFi, ensuring that high-value transactions are not only cryptographically signed but also semantically verified.

## Table of Contents

- [Features](#-key-features)
- [Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [How It Works](#-how-it-works)
- [Development](#-development)
- [Security](#-security--privacy)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)

## 🌟 Key Features

- **🤖 AI Guardian Co-Signing**: A specialized Llama-3-powered agent that analyzes transaction intent and co-signs safe operations.
- **🔐 ZK-Income Verification**: Privacy-preserving "High-Income" badges that unlock higher withdrawal limits without exposing your net worth.
- **💳 Account Abstraction Core**: Built as a programmable smart contract account (SmartVault), moving beyond simple EOAs.
- **⚡ Dual-Signature Validation**: Transactions above a certain threshold (`0.1 ETH`) require cryptographic approval from both the Owner and the AI Guardian.
- **🎨 Modern Dashboard**: A high-performance Next.js 15 frontend with real-time status tracking and interactive signing flows.

## 🎯 Motivation: The $3.8B Security Gap

In 2024 alone, billions were lost to private key compromises and phishing attacks. LockedFI addresses the **"Privacy-Security Bottleneck"** through:
- **Regulatory Compliance vs. Privacy**: Global regulations (GDPR/CCPA) demand data minimization. We provide a solution where "Verification" does not require "Data Storage."
- **Mitigation of EOA Fragility**: Standard wallets rely on a single ECDSA key; a single leak leads to 100% loss. LockedFI moves from "Passive Wallets" to "Active Guardians."
- **The Rise of RWA**: As traditional finance moves on-chain, there is an urgent need for ZK-based attestations that prove income brackets without revealing exact net worth.

## 🏗️ System Architecture

LockedFI operates as a **6-Layer Security Sandwich**, ensuring every transaction is private, intelligent, and verified:

1.  **Input Layer**: User provides an email (DKIM-signed) and a transaction request.
2.  **ZK-Generation Layer**: User's machine computes a zk-SNARK proof locally using `witness_calculator.js`.
3.  **Transport Layer**: The proof and transaction hash are sent to the Node.js/Next.js API Bridge.
4.  **AI Processing Layer**: The API queries Groq (Llama-3.3-70B). The AI evaluates: (Amount, Gas, Recipient, User_Income_Badge).
5.  **Signature Layer**: If approved, the Python service (AI Guardian) signs the `UserOpHash`.
6.  **Blockchain Layer**: `SmartVault.sol` receives the 130-byte bundled signature, verifies it via `ecrecover`, and executes the transfer.

```
┌────────────────────────────────────────────────────────────────┐
│                         USER LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Wallet     │  │  Dashboard   │  │  ZK Circuit  │          │
│  │  (MetaMask)  │  │  (Next.js)   │  │  (Circom/JS) │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
└─────────┼─────────────────┼─────────────────┼──────────────────┘
          │ (1) Input       │ (2) ZK-Gen      │
          ▼                 ▼                 ▼
┌────────────────────────────────────────────────────────────────┐
│                     (3) TRANSPORT LAYER                        │
│  ┌──────────────────────────────────────────────────┐          │
│  │      Next.js API Bridge (/api/approve)           │          │
│  └────────────────────┬─────────────────────────────┘          │
└───────────────────────┼────────────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────────────┐
│                   (4) AI PROCESSING LAYER                      │
│  ┌──────────────────────────────────────────────────┐          │
│  │    Python Service (Groq Llama-3.3-70b)           │          │
│  │    - Evaluate: Amount, Gas, Recipient, Badge     │          │
│  └────────────────────┬─────────────────────────────┘          │
└───────────────────────┼────────────────────────────────────────┘
                        │
                        ▼
┌────────────────────────────────────────────────────────────────┐
│                     (5) SIGNATURE LAYER                        │
│  ┌──────────────────────────────────────────────────┐          │
│  │    AI Guardian (guardian_service.py)             │          │
│  │    - Signs UserOpHash (65-byte AI Sig)           │          │
│  └────────────────────┬─────────────────────────────┘          │
└───────────────────────┼────────────────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────────────────────┐
│                   (6) BLOCKCHAIN LAYER                        │
│  ┌──────────────────┐  ┌─────────────────────────────────┐    │
│  │   SmartVault     │  │    Groth16Verifier              │    │
│  │   .sol           │  │    .sol                         │    │
│  │                  │  │                                 │    │
│  │ - 130b Bundle    │  │ - ZK Proof Validation           │    │
│  │ - ecrecover Check│  │ - Income Badge Verification     │    │
│  │ - Execution      │  │                                 │    │
│  └──────────────────┘  └─────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
```

## 📦 Core Modules

The LockedFI ecosystem is composed of five specialized modules that work in orchestration:

| Module | Responsibility | Location |
|:---|:---|:---|
| **ZK-Circuit (Circom)** | Defines mathematical constraints for income verification and identity hashing (DKIM-ready). | `zk/circuits/` |
| **Smart Vault (Solidity)** | ERC-4337 compliant account handling custody, dual-signatures, and risk limits. | `contracts/src/` |
| **AI Guardian (Python)** | Off-chain risk-analysis engine using Llama-3.3-70B to generate cryptographic co-signatures. | `ai-guardian/` |
| **API Bridge (Next.js)** | Secure middleware coordinating communication between the Frontend, AI Service, and EVM. | `frontend/src/app/api/` |
| **Verifier (Solidity)** | On-chain Groth16 verifier for final elliptic curve pairing checks of ZK-proofs. | `contracts/src/Verifier.sol` |

### Module Relationship Diagram

```text
             ┌────────────────┐          ┌────────────────┐
             │   API Bridge   │ <──────> │  AI Guardian   │
             │   (Next.js)    │          │    (Python)    │
             └───────┬────────┘          └────────┬───────┘
                     │                            │ (Co-signature)
                     ▼                            ▼
             ┌────────────────┐          ┌────────────────┐
             │   ZK-Circuit   │ ───────> │   Smart Vault  │
             │    (Circom)    │          │   (Solidity)   │
             └───────┬────────┘          └────────┬───────┘
                     │                            │
                     ▼                            │
             ┌────────────────┐                   │
             │    Verifier    │ <─────────────────┘
             │   (Solidity)   │      (Verification Call)
             └────────────────┘
```

## 🛠️ Tech Stack

| Category | Technology | Purpose |
|:---|:---|:---|
| **Blockchain** | Solidity 0.8.19+ | Smart contract logic |
| **Framework** | Foundry (Forge, Cast, Anvil) | Ethereum development and testing |
| **ZK-SNARKs** | Circom, SnarkJS (Groth16, BN128) | Zero-knowledge proof generation |
| **AI/LLM** | Groq SDK, Llama-3.3-70b-versatile | Transaction analysis and decision making |
| **Frontend** | Next.js 15, TypeScript, TailwindCSS v4 | User dashboard and interface |
| **Blockchain SDK** | Ethers.js v6 | Web3 integration and transaction signing |
| **Backend** | Node.js (Next.js API Routes) | API endpoints and middleware |

## 🚀 Getting Started

### Prerequisites

- **Foundry**: `curl -L https://foundry.paradigm.xyz | bash`
- **Node.js**: v18 or newer
- **Python**: v3.10+
- **Groq API Key**: Obtain from [Groq Console](https://console.groq.com/)
- **Brave Wallet** or **MetaMask**: For wallet connection

### Quick Start

LockedFI is designed for a seamless, "one-command" setup experience.

```bash
# Clone the repository and navigate to the root
cd LockedFI

# Make the start script executable
chmod +x start.sh

# Launch the entire stack (Blockchain, AI Service, and Dashboard)
./start.sh
```

The script will automatically:
1. Check for all system dependencies
2. Install necessary packages for frontend and AI guardian
3. Launch the local blockchain (Anvil)
4. Deploy smart contracts
5. Update configuration files
6. Initialize vault state
7. Launch the user dashboard

Once complete, access the dashboard at **http://localhost:3000**

### Manual Setup (Advanced)

If you prefer to run components separately:

#### 1. Start Local Blockchain

```bash
anvil --port 8545 --silent
```

#### 2. Deploy Contracts

```bash
cd contracts

# Deploy Verifier
forge create \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast \
  src/Verifier.sol:Groth16Verifier

# Deploy Smart Vault (replace with actual verifier address)
forge create \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast \
  src/SmartVault.sol:SmartVault \
  --constructor-args \
    0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
    0x4e507a4575d71c1E7EAAfaB9F6Ff0fde730DeD29 \
    <VERIFIER_ADDRESS>
```

#### 3. Setup AI Guardian

```bash
cd ai-guardian

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install groq eth-account python-dotenv

# Create .env file
echo "GROQ_API_KEY=your_groq_api_key_here" > .env
echo "PRIVATE_KEY=0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abcd" >> .env
```

#### 4. Start Frontend

```bash
cd frontend

# Install dependencies
npm install

# Update contract addresses in src/constants/vault.ts

# Start development server
npm run dev
```

## 📁 Project Structure

```
LockedFI/
├── contracts/               # Smart contracts
│   ├── src/
│   │   ├── SmartVault.sol  # Main vault contract with dual-signature logic
│   │   └── Verifier.sol    # Groth16 ZK proof verifier
│   ├── script/
│   │   └── Deploy.s.sol    # Deployment script
│   ├── lib/                # Foundry dependencies
│   └── foundry.toml        # Foundry configuration
├── frontend/               # Next.js dashboard
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.tsx            # Main dashboard component
│   │   │   ├── layout.tsx          # App layout
│   │   │   └── api/
│   │   │       └── approve/
│   │   │           └── route.ts    # AI approval endpoint
│   │   └── constants/
│   │       └── vault.ts           # Contract ABI and address
│   ├── package.json
│   └── tailwind.config.ts
├── ai-guardian/            # Python AI service
│   ├── guardian_service.py # Main AI guardian service
│   ├── bundler.py         # Transaction bundling utilities
│   ├── check_key.py       # API key validation
│   └── venv/              # Python virtual environment
├── start.sh              # Unified launcher script
├── README.md             # This file
└── TECHNICAL_SPECIFICATION.md  # Detailed technical documentation
```

## 🔄 How It Works

### Transaction Lifecycle

1. **Initialization**
   - User connects wallet to the LockedFI Dashboard
   - Dashboard displays current vault status (balance, badge status)

2. **Verification (Optional)**
   - User generates a ZK-Proof locally using the Circom circuit
   - Proof is submitted to `SmartVault.sol` to earn "High-Income Badge"
   - Badge status is stored on-chain as `hasHighIncomeBadge`

3. **Withdrawal Request**
   - User initiates withdrawal from dashboard
   - Transaction hash is generated: `ethers.id("withdraw_" + Date.now())`

4. **Owner Signing**
   - Wallet prompts user to sign transaction hash
   - Signature is captured (65 bytes)

5. **AI Analysis**
   - Transaction context is sent to `/api/approve` endpoint
   - API forwards request to AI Guardian service
   - AI analyzes transaction intent and safety
   - If approved, AI Guardian signs the transaction hash (65 bytes)

6. **Signature Bundling**
   - Owner signature + AI signature are combined (130 bytes total)
   - Bundle is sent to SmartVault contract

7. **On-Chain Validation**
   - `SmartVault.validateUserOp()` verifies both signatures
   - Checks that signatures are from valid Owner and AI Guardian
   - Validates `hasHighIncomeBadge` if amount > RISK_LIMIT

8. **Execution**
   - If all validations pass, `SmartVault.execute()` transfers funds
   - Transaction is confirmed on-chain

### Risk Limits

- **Default RISK_LIMIT**: `0.1 ETH`
- Transactions below limit: Owner signature only required
- Transactions above limit: Dual signature + High-Income Badge required

## 🛡️ Security & Privacy

### Privacy Features

- **Data Minimization**: Your raw income data never leaves your browser. Only the ZK-Proof is transmitted.
- **Zero-Knowledge**: The blockchain only knows that you meet the income threshold, not your actual balance.
- **Local Processing**: All sensitive cryptographic operations happen on your device.

### Security Considerations

**⚠️ IMPORTANT**: This is a **technical prototype** designed for demonstration and educational purposes.

For production use, consider:
- **AI Guardian Security**: Host the AI Guardian in a Trusted Execution Environment (TEE)
- **Key Management**: Use hardware-backed HSM/KMS for private key storage
- **Smart Contract Audit**: Professional security audit before mainnet deployment
- **Multi-Agent Consensus**: Replace single AI with decentralized AI consensus
- **Fail-Safe Mechanisms**: Implement recovery procedures for service outages

### Threat Model

- **Trusted Components**: AI Guardian (can be replaced with DeAI in production)
- **Attack Surface**: Web3 wallet, API endpoints, smart contract
- **Mitigation**: ZK-proofs, dual-signature validation, rate limiting

## 🔧 Development

### Running Tests

```bash
# Smart contract tests
cd contracts
forge test

# Frontend tests
cd frontend
npm test
```

### Building for Production

```bash
# Build smart contracts
cd contracts
forge build

# Build frontend
cd frontend
npm run build
```

### Environment Variables

Create a `.env` file in the `ai-guardian` directory:

```env
# Groq API Key for AI Guardian
GROQ_API_KEY=your_groq_api_key_here

# AI Guardian Private Key (for co-signing)
PRIVATE_KEY=0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abcd
```

## 🗺️ Roadmap

### Phase 1: Prototype ✅ (Current)
- Basic dual-signature validation
- ZK-income verification
- Simple AI guardian
- Demo dashboard

### Phase 2: Enhancement
- Multi-agent consensus for Guardian layer
- Dynamic risk limits based on on-chain volatility
- Enhanced ZK circuits for more complex proofs
- Improved AI decision-making with historical data

### Phase 3: Production Readiness
- Mainnet-ready security audit
- KMS integration for key management
- TEE-based AI Guardian deployment
- Gas optimization and cost reduction
- Recovery mechanisms for lost access

### Phase 4: Ecosystem Expansion
- Support for multiple blockchain networks
- Integration with popular wallets
- Mobile application
- Community governance features
- DeFi protocol integrations

## 📞 Support

- **Documentation**: Check [TECHNICAL_SPECIFICATION.md](TECHNICAL_SPECIFICATION.md) for detailed technical documentation
- **Issues**: Report bugs and feature requests on GitHub Issues
- **Discussions**: Join our community discussions

## 🙏 Acknowledgments

- [Groq](https://groq.com/) - For providing fast AI inference
- [Foundry](https://getfoundry.sh/) - For the excellent development toolkit
- [OpenZeppelin](https://openzeppelin.com/) - For secure smart contract libraries
- [Circom](https://docs.circom.io/) - For ZK circuit development

---

**Built with ❤️ for the future of decentralized finance**