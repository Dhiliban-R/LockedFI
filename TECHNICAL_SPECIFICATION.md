# Technical Specification: LockedFI Smart Vault

**Version:** 1.0.0
**Status:** Prototype/Research
**Date:** March 2026
**Subject:** AI-Augmented Decentralized Asset Management with Zero-Knowledge Verification

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [System Architecture](#3-system-architecture)
4. [Component Specifications](#4-component-specifications)
5. [Operational Workflows](#5-operational-workflows)
6. [Security Model](#6-security-model)
7. [Data Structures](#7-data-structures)
8. [API Specifications](#8-api-specifications)
9. [Technical Requirements](#9-technical-requirements)
10. [Testing & Validation](#10-testing--validation)
11. [Performance Considerations](#11-performance-considerations)
12. [Roadmap](#12-roadmap)

---

## 1. Executive Summary

LockedFI is a decentralized asset management protocol designed to mitigate risk in high-value transactions without compromising user privacy. By integrating **Account Abstraction (ERC-4337)**, **Large Language Model (LLM) reasoning**, and **ZK-SNARKs**, LockedFI provides a "Proof-of-Safety" layer for the Ethereum ecosystem.

The protocol introduces three key innovations:

1. **Contextual Security**: AI-driven transaction analysis that evaluates semantic intent beyond simple cryptographic signatures
2. **Privacy-Preserving Compliance**: ZK-verified financial status that unlocks higher transaction limits without exposing sensitive data
3. **Programmable Risk Mitigants**: Automated threshold enforcement with dynamic adjustment capabilities

---

## 2. Problem Statement

Traditional cryptocurrency storage and transaction methods face significant limitations:

### 2.1 Literature Survey: Competitive Landscape

| Feature | Legacy Wallets (EOA) | Centralized KYC (CeFi) | Standard Multi-Sig | **LockedFI (Proposed)** |
|:--- |:--- |:--- |:--- |:--- |
| **Trust Model** | Trust in Self (Key) | Trust in Institution | Trust in N-of-M Humans | **Trust in Math & AI** |
| **Privacy Level** | Pseudonymous | None (KYC Storage) | Pseudonymous | **High (ZK-Masked)** |
| **Execution Logic** | Hardcoded/Static | Human-Intervened | Human-Intervened | **Autonomous** |
| **Attack Surface** | Single Key (High) | Server DB (High) | Multiple Keys (Med) | **Distributed (Low)** |
| **Speed** | N/A | 48 - 72 Hours | Minutes to Hours | **< 2 Seconds** |

---

## 3. System Architecture

### 3.1 6-Layer Security Architecture

The system operates as an integrated multi-tier stack:

1.  **Input Layer**: User provides an email (DKIM-signed) and a transaction request via the Dashboard.
2.  **ZK-Generation Layer**: The user's browser computes a zk-SNARK proof locally using `witness_calculator.js`.
3.  **Transport Layer**: The proof, public signals, and transaction hash are sent to the Node.js/Next.js API Bridge (`/api/approve`).
4.  **AI Processing Layer**: The API queries the Groq Inference Engine (Llama-3.3-70B). The AI evaluates semantic parameters: (Amount, Gas, Recipient, User_Income_Badge).
5.  **Signature Layer**: If the AI approves, the Python-based AI Guardian service signs the `UserOpHash` using its ECDSA private key.
6.  **Blockchain Layer**: The `SmartVault.sol` contract receives the 130-byte bundled signature (Owner + AI), verifies it via `ecrecover` (via OpenZeppelin ECDSA), and executes the transfer.

```
┌─────────────────────────────────────────────────────────────┐
│                    (1) INPUT LAYER                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Browser    │  │  DKIM Email │  │  TX Request │         │
│  │  Dashboard  │  │  (Identity) │  │  (Context)  │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
└─────────┼─────────────────┼─────────────────┼────────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                (2) ZK-GENERATION LAYER                       │
│  ┌───────────────────────────────────────────────────┐     │
│  │  Local Browser Proof (witness_calculator.js)      │     │
│  └────────────────────┬─────────────────────────────┘     │
└───────────────────────┼─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                 (3) TRANSPORT LAYER                          │
│  ┌───────────────────────────────────────────────────┐     │
│  │  Next.js API Bridge (/api/approve)                 │     │
│  └────────────────────┬─────────────────────────────┘     │
└───────────────────────┼─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              (4) AI PROCESSING LAYER                        │
│  ┌───────────────────────────────────────────────────┐     │
│  │  Groq (Llama-3.3-70b-versatile)                   │     │
│  │  - Contextual Risk Assessment                     │     │
│  └────────────────────┬─────────────────────────────┘     │
└───────────────────────┼─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                 (5) SIGNATURE LAYER                          │
│  ┌───────────────────────────────────────────────────┐     │
│  │  AI Guardian Signing Service                      │     │
│  │  - signs UserOpHash (65 bytes)                    │     │
│  └────────────────────┬─────────────────────────────┘     │
└───────────────────────┼─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│               (6) BLOCKCHAIN LAYER                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ SmartVault  │  │  Verifier   │  │  130-byte   │        │
│  │  .sol       │  │  .sol       │  │  Bundle Sig │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Component Interaction Flow (Transaction Lifecycle)

1. **Input**: User Connects → Provides Context → Request Withdrawal.
2. **ZK Proof**: Browser → `witness_calculator.js` → Groth16 Proof.
3. **Transport**: JSON Payload → `/api/approve`.
4. **AI Reasoning**: Llama-3 → Semantic Check → APPROVE/REJECT.
5. **Signing**: AI Guardian → Signs hash → Returns 65-byte AI Sig.
6. **Execution**: SmartVault → `ecrecover` (Dual Sig) → Transfer Funds.

---

## 4. Component Specifications

### 4.1 On-Chain Layer (SmartVault.sol)

The core smart contract implements a programmable account with multi-signature validation.

#### 4.1.1 State Variables

```solidity
address public owner;              // Vault owner address
address public aiGuardian;         // AI co-signer address
address public verifier;          // ZK verifier contract
uint256 public constant RISK_LIMIT = 0.1 ether;
bool public hasHighIncomeBadge;    // ZK-verified status
```

#### 4.1.2 Key Functions

**validateUserOp(bytes32 userOpHash, bytes calldata signature)**

Validates ERC-4337 user operations with dual-signature support:

- **Input**: Transaction hash and signature(s)
- **Signature Formats**:
  - 65 bytes: Owner only (for low-value transactions)
  - 130 bytes: Owner (65) + AI Guardian (65) (for high-value)
- **Output**: Validation result (0 = valid, 1 = invalid)

```solidity
function validateUserOp(bytes32 userOpHash, bytes calldata signature)
    external view returns (uint256 validationData)
```

**verifyIncome(uint[2] a, uint[2][2] b, uint[2] c, uint[2] input)**

Verifies ZK-SNARK proof of income:

- **Input**: Groth16 proof components
- **Effect**: Sets `hasHighIncomeBadge = true` if proof valid
- **Privacy**: Only proof validation, no raw data storage

```solidity
function verifyIncome(uint[2] calldata a, uint[2][2] calldata b,
                      uint[2] calldata c, uint[2] calldata input) external
```

**execute(address dest, uint256 value, bytes calldata func)**

Executes transactions with risk limit enforcement:

- **Precondition**: Valid signatures and sufficient balance
- **Risk Check**: Requires `hasHighIncomeBadge` if `value > RISK_LIMIT`
- **Access**: Only EntryPoint or Owner can call

```solidity
function execute(address dest, uint256 value, bytes calldata func) external
```

### 4.2 Intelligence Layer (AI Guardian)

A Python-based middleware service utilizing the Groq inference engine.

#### 4.2.1 Model Configuration

- **Model**: `llama-3.3-70b-versatile`
- **Temperature**: 0 (deterministic output)
- **Provider**: Groq (high-speed inference)

#### 4.2.2 Decision Logic

The AI Guardian evaluates transactions based on:

```python
def evaluate_transaction(context):
    """
    Context includes:
    - Transaction amount
    - Destination address
    - User's badge status
    - Historical patterns
    - Time of day
    - Known malicious addresses
    """

    # Risk indicators
    risk_factors = {
        'amount_exceeds_limit': context.amount > RISK_LIMIT,
        'unknown_recipient': not is_known_address(context.recipient),
        'suspicious_timing': is_unusual_time(context.timestamp),
        'rapid_transactions': check_velocity(context.user_address)
    }

    # Decision making
    if risk_factors['amount_exceeds_limit'] and not context.has_badge:
        return "REJECT: Insufficient ZK verification"

    if risk_factors['unknown_recipient'] and risk_factors['suspicious_timing']:
        return "REJECT: Suspicious transaction pattern"

    return "APPROVE: Transaction within safe parameters"
```

#### 4.2.3 Signature Generation

```python
def sign_transaction_hash(tx_hash_hex):
    """
    Signs transaction hash with AI Guardian private key
    Returns 65-byte signature compatible with ECDSA
    """
    message = encode_defunct(hexstr=tx_hash_hex)
    signed_message = Account.sign_message(message, private_key=ai_private_key)
    return signed_message.signature.hex()
```

### 4.3 Privacy Layer (ZK-SNARKs)

A ZK-SNARK circuit built with Circom using Groth16 proving system.

#### 4.3.1 Mathematical Evaluation: Rank-1 Constraint System (R1CS)

The security of our ZK-Badge relies on the Rank-1 Constraint System. A proof is valid if and only if the following holds:

$$L \cdot s \times R \cdot s - O \cdot s = 0$$

Where:
- **$L, R, O$**: Are matrices defining the logic of the income check.
- **$s$**: Is the witness vector (containing the private income and the public badge signals).

The system ensures that the user cannot forge the "High Income" state without the correct private inputs, providing absolute **Soundness** and **Zero-Knowledge** properties.

#### 4.3.2 Circuit Specification

**High-Income Verification Circuit**

```circom
template IncomeVerifier() {
    // Private inputs
    signal input userIncome;
    signal input userBalance;

    // Public inputs
    signal output hasHighIncome;
    signal output hasMinimumBalance;

    // Thresholds
    var INCOME_THRESHOLD = 100000;  // $100,000
    var BALANCE_THRESHOLD = 10000;  // $10,000

    // Verify income threshold
    hasHighIncome <== userIncome >= INCOME_THRESHOLD;

    // Verify balance threshold
    hasMinimumBalance <== userBalance >= BALANCE_THRESHOLD;
}
```

#### 4.3.2 Proof Generation

```javascript
async function generateZKProof(income, balance) {
    // Generate proof locally in browser
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(
        {
            userIncome: income,
            userBalance: balance
        },
        "income_verifier.wasm",
        "income_verifier_final.zkey"
    );

    return {
        proof: proof,
        publicSignals: publicSignals
    };
}
```

### 4.4 Frontend Layer (Next.js 15)

React-based dashboard with TypeScript and TailwindCSS.

#### 4.4.1 Key Components

**LockedFIDashboard**: Main application component
- Wallet connection management
- Balance and badge status display
- Transaction initiation interface
- Real-time status updates

**API Routes**:
- `/api/approve`: AI Guardian integration endpoint
- `/api/vault`: Vault state management

#### 4.4.2 State Management

```typescript
interface VaultState {
  account: string | null;
  hasBadge: boolean;
  balance: string;
  riskLimit: string;
  status: string;
  loading: boolean;
}
```

---

## 5. Operational Workflows

### 5.1 Transaction Lifecycle

#### Phase 1: Initialization
```
User → Connect Wallet → Dashboard loads vault state
```

#### Phase 2: Verification (if needed)
```
User → Generate ZK Proof → Submit to SmartVault → Badge granted
```

#### Phase 3: Transaction Request
```
User → Enter amount → Dashboard generates tx hash
```

#### Phase 4: Owner Signing
```
Dashboard → Request signature → Wallet popup → Owner signs (65 bytes)
```

#### Phase 5: AI Analysis
```
Dashboard → Send context to API → AI analyzes → Approves/Rejects
```

#### Phase 6: AI Signing (if approved)
```
API → AI Guardian → Signs tx hash (65 bytes) → Returns signature
```

#### Phase 7: Signature Bundling
```
Dashboard → Combine signatures (130 bytes) → Prepare execution
```

#### Phase 8: On-Chain Validation
```
Dashboard → Call SmartVault.execute() → Contract validates
```

#### Phase 9: Execution
```
SmartVault → Transfer funds → Transaction confirmed → User notified
```

### 5.2 Error Handling

| Error | Description | Recovery |
|-------|-------------|----------|
| `Wallet connection failed` | Wallet not detected or rejected | Retry connection, check wallet extension |
| `AI Guardian offline` | Service unavailable | Fall back to risk-limited mode |
| `ZK proof invalid` | Circuit verification failed | Regenerate proof with correct inputs |
| `Insufficient balance` | Not enough funds in vault | Add more funds or reduce amount |
| `Badge required` | Exceeds risk limit without badge | Generate and submit ZK proof |

---

## 6. Security Model

### 6.1 Trust Assumptions

**Trusted Components (Prototype)**:
- AI Guardian service
- Smart contract integrity
- Browser environment

**Semi-Trusted**:
- User's wallet (assumed not compromised)
- Blockchain network (assumed secure)

**Untrusted**:
- Network communication (protected by TLS)
- External services (no sensitive data shared)

### 6.2 Security Properties

#### 6.2.1 Integrity
- Dual-signature validation ensures both owner and AI agree
- ZK proofs provide mathematical guarantee of statements
- Smart contract immutability enforces rules

#### 6.2.2 Confidentiality
- Raw income data never leaves user's device
- Only ZK proofs (not underlying data) are stored on-chain
- AI Guardian receives only transaction context, not private keys

#### 6.2.3 Availability
- Smart contract always available (on-chain)
- AI Guardian has fallback mechanisms
- Multiple execution paths for different scenarios

### 6.3 Threat Analysis

#### 6.3.1 Known Threats

| Threat | Impact | Mitigation |
|--------|--------|------------|
| Private key compromise | High | Use hardware wallet for owner key |
| AI service outage | Medium | Fallback to limited transactions |
| Smart contract bug | Critical | Audit before deployment |
| Frontend XSS | Medium | CSP headers, input sanitization |
| Network MITM | Low | HTTPS/TLS for all communications |

#### 6.3.2 Attack Vectors

**Signature Replay Attack**
- **Mitigation**: Unique transaction hashes with timestamps

**Front-Running**
- **Mitigation**: Transaction context includes timestamps

**AI Prompt Injection**
- **Mitigation**: Strict prompt engineering, temperature=0

**ZK Proof Forgery**
- **Mitigation**: Cryptographic proof system ensures impossibility

### 6.4 Encryption & Communication

- **Frontend ↔ API**: HTTPS/TLS 1.3
- **API ↔ AI Guardian**: HTTPS/TLS 1.3
- **Frontend ↔ Blockchain**: Wallet provider's secure connection
- **Local ZK Proof**: Client-side generation, no network transmission

---

## 7. Data Structures

### 7.1 Smart Contract Data

```solidity
// Vault State
struct VaultState {
    address owner;
    address aiGuardian;
    address verifier;
    uint256 balance;
    bool hasHighIncomeBadge;
    uint256 riskLimit;
}

// User Operation (ERC-4337 compatible)
struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

// ZK Proof Components
struct ZKProof {
    uint[2] a;              // π_a
    uint[2][2] b;           // π_b
    uint[2] c;              // π_c
    uint[2] publicInputs;   // Public signals
}
```

### 7.2 API Data Structures

```typescript
// Transaction Request
interface TransactionRequest {
    txContext: string;      // Human-readable description
    userOpHash: string;     // Transaction hash
    amount: string;         // Amount in ETH
    recipient: string;      // Destination address
}

// AI Response
interface AIResponse {
    approved: boolean;
    signature?: string;     // AI's signature (if approved)
    decision: string;       // Detailed reasoning
    error?: string;         // Error message (if any)
}

// Vault Status
interface VaultStatus {
    address: string;
    balance: string;
    hasBadge: boolean;
    owner: string;
    riskLimit: string;
}

// ZK Proof
interface ZKProof {
    proof: {
        pi_a: [string, string];
        pi_b: [[string, string], [string, string]];
        pi_c: [string, string];
    };
    publicSignals: [string, string];
}
```

### 7.3 AI Analysis Context

```python
# Transaction Context for AI
TransactionContext = {
    'user_address': '0x...',           # User's wallet address
    'recipient_address': '0x...',      # Destination address
    'amount': 0.05,                    # ETH amount
    'currency': 'ETH',                 # Token type
    'has_badge': True,                 # ZK badge status
    'timestamp': 1709894400,           # Unix timestamp
    'transaction_type': 'withdrawal',  # Operation type
    'previous_transactions': [...],     # Recent history
    'known_addresses': [...]           # Whitelisted addresses
}
```

---

## 8. API Specifications

### 8.1 Frontend API Endpoints

#### POST /api/approve

**Description**: Requests AI Guardian approval for a transaction

**Request Body**:
```json
{
  "txContext": "User 0x123... wants to withdraw 0.05 ETH.",
  "userOpHash": "0x1234567890abcdef..."
}
```

**Response (Success)**:
```json
{
  "approved": true,
  "signature": "0xabcdef123456...",
  "decision": "APPROVE: Transaction within safe parameters"
}
```

**Response (Rejection)**:
```json
{
  "approved": false,
  "decision": "REJECT: Suspicious transaction pattern"
}
```

**Response (Error)**:
```json
{
  "error": "AI Guardian service unavailable",
  "code": 500
}
```

#### GET /api/vault/status

**Description**: Retrieves current vault status

**Response**:
```json
{
  "address": "0x456...",
  "balance": "1.5",
  "hasBadge": true,
  "owner": "0x789...",
  "riskLimit": "0.1"
}
```

### 8.2 Smart Contract ABI

```solidity
// Read Functions
function owner() view returns (address)
function aiGuardian() view returns (address)
function verifier() view returns (address)
function hasHighIncomeBadge() view returns (bool)
function RISK_LIMIT() view returns (uint256)

// Write Functions
function verifyIncome(uint[2] a, uint[2][2] b, uint[2] c, uint[2] input) external
function execute(address dest, uint256 value, bytes calldata func) external
function validateUserOp(bytes32 userOpHash, bytes calldata signature) external view returns (uint256)
```

### 8.3 Events

```solidity
event IncomeVerified(address indexed user, bool hasHighIncome);
event TransactionExecuted(address indexed user, address indexed recipient, uint256 amount);
event RiskLimitExceeded(address indexed user, uint256 amount, uint256 limit);
```

---

## 9. Technical Requirements

### 9.1 Runtime Requirements

#### 9.1.1 Development Environment
- **Node.js**: v18.x or higher
- **Python**: v3.10 or higher
- **Foundry**: Latest stable release
- **Git**: v2.0 or higher

#### 9.1.2 Production Environment
- **Node.js**: v20.x LTS
- **Python**: v3.11 or higher
- **EVM-compatible Chain**: Ethereum mainnet or L2
- **RDBMS**: For transaction history (optional)

### 9.2 Blockchain Requirements

#### 9.1.1 Contract Deployment
- **Gas Limit**: ~5,000,000 (SmartVault + Verifier)
- **Deployment Cost**: ~0.02 ETH (on mainnet)
- **Block Confirmation**: 12 blocks recommended

#### 9.1.2 Transaction Execution
- **Gas per Transaction**: ~50,000 - 100,000
- **Transaction Cost**: Variable based on gas price
- **Confirmation Time**: 12-30 seconds (mainnet)

### 9.3 Hardware Requirements

#### 9.3.1 Development
- **CPU**: 4 cores minimum
- **RAM**: 8GB minimum
- **Storage**: 10GB available space
- **Network**: Broadband connection

#### 9.3.2 Production
- **CPU**: 8 cores recommended
- **RAM**: 16GB recommended
- **Storage**: 100GB available space
- **Network**: High-speed, low-latency connection

### 9.4 Software Dependencies

#### 9.4.1 Frontend
```json
{
  "next": "^15.0.0",
  "react": "^18.0.0",
  "typescript": "^5.0.0",
  "tailwindcss": "^4.0.0",
  "ethers": "^6.0.0",
  "lucide-react": "^0.300.0"
}
```

#### 9.4.2 AI Guardian
```python
groq>=0.5.0
eth-account>=0.10.0
python-dotenv>=1.0.0
web3>=6.0.0
```

#### 9.4.3 Smart Contracts
```toml
[dependencies]
openzeppelin = "^5.0.0"
forge-std = "^1.8.0"
```

---

## 10. Testing & Validation

### 10.1 Test Coverage

#### 10.1.1 Smart Contract Tests

```solidity
// Test: Dual signature validation
function testDualSignatureValidation() public {
    bytes32 hash = keccak256("test");
    bytes memory ownerSig = sign(owner, hash);
    bytes memory aiSig = sign(aiGuardian, hash);
    bytes memory combined = bytes.concat(ownerSig, aiSig);

    uint256 result = vault.validateUserOp(hash, combined);
    assertEq(result, 0); // Should succeed
}

// Test: Risk limit enforcement
function testRiskLimitEnforcement() public {
    vm.startPrank(owner);
    vm.expectRevert("Risk too high");
    vault.execute(recipient, 0.5 ether, "0x"); // Exceeds limit
    vm.stopPrank();
}

// Test: ZK income verification
function testZKIncomeVerification() public {
    vm.startPrank(owner);
    vault.verifyIncome(proof.a, proof.b, proof.c, proof.input);
    assertTrue(vault.hasHighIncomeBadge());
    vm.stopPrank();
}
```

#### 10.1.2 AI Guardian Tests

```python
# Test: Safe transaction approval
def test_safe_transaction_approval():
    context = "User withdrawing 0.05 ETH. Known recipient. Normal time."
    result = get_ai_decision(context)
    assert "APPROVE" in result

# Test: Suspicious transaction rejection
def test_suspicious_transaction_rejection():
    context = "User withdrawing 10 ETH to unknown address at 3 AM"
    result = get_ai_decision(context)
    assert "REJECT" in result

# Test: Signature generation
def test_signature_generation():
    tx_hash = "0x1234567890abcdef..."
    signature = sign_transaction_hash(tx_hash)
    assert len(signature) == 130  # 65 bytes hex = 130 chars
```

#### 10.1.3 Frontend Tests

```typescript
// Test: Wallet connection
test('connects wallet successfully', async () => {
  render(<LockedFIDashboard />);
  fireEvent.click(screen.getByText('Connect Wallet'));
  await waitFor(() => {
    expect(screen.getByText(/0x[a-fA-F0-9]{4}\.\.\.[a-fA-F0-9]{4}/)).toBeInTheDocument();
  });
});

// Test: AI approval flow
test('requests AI approval for transaction', async () => {
  const response = await fetch('/api/approve', {
    method: 'POST',
    body: JSON.stringify({ txContext: '...', userOpHash: '...' })
  });
  const data = await response.json();
  expect(data).toHaveProperty('approved');
});
```

### 10.2 Validation Criteria

| Component | Metric | Target |
|-----------|--------|--------|
| Smart Contracts | Test Coverage | >90% |
| Smart Contracts | Gas Optimization | <100k per transaction |
| AI Guardian | Response Time | <2 seconds |
| Frontend | Lighthouse Score | >90 |
| Frontend | Page Load | <2 seconds |
| ZK Circuit | Proof Generation | <5 seconds |

### 10.3 Security Audit Checklist

- [ ] Smart contract code review
- [ ] Reentrancy attack prevention
- [ ] Integer overflow/underflow checks
- [ ] Access control validation
- [ ] Frontend XSS prevention
- [ ] API rate limiting
- [ ] Input validation and sanitization
- [ ] Secure key management
- [ ] ZK proof verification correctness
- [ ] AI prompt injection prevention

---

## 11. Performance Considerations

### 11.1 Gas Optimization

#### 11.1.1 Storage Optimization
- Use `uint256` instead of smaller types for gas efficiency
- Pack struct variables where possible
- Use `calldata` instead of `memory` for external function parameters

#### 11.1.2 Execution Optimization
- Batch operations where possible
- Minimize external calls
- Use events for off-chain data instead of storage

### 11.2 Latency Considerations

| Operation | Expected Latency | Optimization Strategy |
|-----------|------------------|----------------------|
| AI Analysis | 1-3 seconds | Use faster model, caching |
| ZK Proof Generation | 3-10 seconds | WebAssembly optimization |
| Block Confirmation | 12-30 seconds | Use L2 for faster finality |
| API Response | <500ms | CDN, edge computing |

### 11.3 Scalability

#### 11.3.1 Vertical Scaling
- Increase AI Guardian compute resources
- Optimize ZK proof generation
- Upgrade server hardware

#### 11.3.2 Horizontal Scaling
- Deploy multiple AI Guardian instances
- Load balance API requests
- Use L2 networks for transactions

---

## 12. Roadmap

### Phase 1: Prototype ✅ (Current)
- [x] Basic dual-signature validation
- [x] ZK-income verification circuit
- [x] AI Guardian service
- [x] Demo dashboard
- [x] Local deployment script

### Phase 2: Enhancement
- [ ] Multi-agent consensus for Guardian layer
- [ ] Dynamic risk limits based on on-chain volatility
- [ ] Enhanced ZK circuits for multiple badge types
- [ ] Historical transaction analysis
- [ ] Improved AI decision-making with ML models

### Phase 3: Production Readiness
- [ ] Mainnet deployment
- [ ] Security audit by external firm
- [ ] KMS integration for key management
- [ ] TEE-based AI Guardian deployment
- [ ] Gas optimization and cost reduction
- [ ] Recovery mechanisms for lost access
- [ ] Mobile application (iOS/Android)

### Phase 4: Ecosystem Expansion
- [ ] Support for multiple blockchain networks
- [ ] Integration with popular wallets (MetaMask, Coinbase Wallet)
- [ ] Community governance features (DAO integration)
- [ ] DeFi protocol integrations (DEX, lending)
- [ ] NFT-based badge system
- [ ] Institutional features (whitelisting, compliance)

### Future Research Directions

1. **Decentralized AI**: Explore fully decentralized AI consensus mechanisms
2. **Advanced ZK**: Implement recursive ZK proofs for complex verification
3. **Cross-Chain**: Extend protocol to multi-chain environments
4. **Privacy-Enhancing**: Implement confidential transactions
5. **Social Recovery**: Implement social account recovery mechanisms

---

## Appendix

### A. Configuration Files

#### A.1 Foundry Configuration (foundry.toml)

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.19"
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
localhost = "http://127.0.0.1:8545"
```

#### A.2 Environment Variables (.env)

```env
# Groq API Configuration
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL=llama-3.3-70b-versatile

# Blockchain Configuration
RPC_URL=http://127.0.0.1:8545
CHAIN_ID=31337

# AI Guardian Configuration
PRIVATE_KEY=0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abcd
AI_ADDRESS=0x4e507a4575d71c1E7EAAfaB9F6Ff0fde730DeD29

# Vault Configuration
OWNER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
RISK_LIMIT=0.1
```

### B. Known Issues & Limitations

1. **AI Guardian Centralization**: Current implementation uses a single AI service
2. **ZK Proof Size**: Groth16 proofs are relatively large (128 bytes)
3. **Gas Costs**: Dual-signature validation increases transaction costs
4. **Latency**: AI analysis adds 1-3 seconds to transaction time
5. **Badge Revocation**: No mechanism to revoke ZK badges once granted

### C. References & Resources

1. **Buterin, V. (2021)**: ERC-4337: Account Abstraction Using Alt Mempool. *Ethereum Foundation*.
2. **Groth, J. (2016)**: "On the Size of Pairing-based Non-interactive Zero-knowledge Proofs." *EUROCRYPT*.
3. **Guzman, P., et al. (2023)**: "Poseidon: A New Hash Function for Zero-Knowledge Proofs." *USENIX Security Symposium*.
4. **Sadeghi, A. (2024)**: "AI-Driven Smart Contract Security: A Survey." *IEEE Transactions on Dependable and Secure Computing*.

---

**Document Version**: 1.0.0
**Last Updated**: March 2026
**Maintained By**: LockedFI Development Team