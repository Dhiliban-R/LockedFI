#!/bin/bash

# LockedFI Unified Launcher 🚀
# This script automates the entire setup, deployment, and execution process.

PROJECT_ROOT=$(pwd)
ANVIL_PORT=8545
FRONTEND_PORT=3000

# Color coding for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}      LockedFI: AI-Guarded ZK-Smart Vault      ${NC}"
echo -e "${BLUE}================================================${NC}"

# Function to cleanup processes on exit
cleanup() {
    echo -e "
${RED}🛑 Shutting down LockedFI Demo...${NC}"
    kill $ANVIL_PID $FRONTEND_PID 2>/dev/null
    pkill -f "next-server" 2>/dev/null || true
    echo -e "${GREEN}✅ Cleanup complete. Goodbye!${NC}"
    exit
}

# Trap Ctrl+C (SIGINT)
trap cleanup SIGINT

# 1. Dependency Checks
echo -e "
${BLUE}Step 1: Checking Dependencies...${NC}"

check_cmd() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ Error: $1 is not installed.${NC}"
        exit 1
    fi
}

check_cmd forge
check_cmd anvil
check_cmd npm
check_cmd python3

echo -e "${GREEN}✅ All system dependencies found.${NC}"

# 2. Package Installation
echo -e "
${BLUE}Step 2: Installing Packages (this may take a moment)...${NC}"

# Frontend
cd "$PROJECT_ROOT/frontend"
if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install --silent
fi

# AI Guardian (Python)
cd "$PROJECT_ROOT/ai-guardian"
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi
source venv/bin/activate
pip install -q groq eth-account python-dotenv

echo -e "${GREEN}✅ Packages installed.${NC}"

# 3. Network Setup
echo -e "
${BLUE}Step 3: Launching Local Blockchain...${NC}"
pkill -f anvil 2>/dev/null || true
anvil --port $ANVIL_PORT --silent > /dev/null 2>&1 &
ANVIL_PID=$!

# Wait for Anvil to be ready
while ! (echo > /dev/tcp/localhost/$ANVIL_PORT) >/dev/null 2>&1; do sleep 1; done
echo -e "${GREEN}✅ Anvil Active on port $ANVIL_PORT.${NC}"

# 4. Deployment & Configuration
echo -e "
${BLUE}Step 4: Deploying Smart Contracts...${NC}"

# Constants for deployment
RPC_URL="http://127.0.0.1:$ANVIL_PORT"
PRIV_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
OWNER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
AI_ADDR="0x4e507a4575d71c1E7EAAfaB9F6Ff0fde730DeD29"
AI_PRIV_KEY="YOUR_AI_PRIVATE_KEY_HERE"
GROQ_KEY="YOUR_GROQ_API_KEY_HERE"

cd "$PROJECT_ROOT/contracts"

# Deploy Verifier
V_OUTPUT=$(forge create --rpc-url $RPC_URL --private-key $PRIV_KEY --broadcast src/Verifier.sol:Groth16Verifier 2>/dev/null)
V_ADDR=$(echo "$V_OUTPUT" | grep "Deployed to:" | awk '{print $3}')

# Deploy Smart Vault
VAULT_OUTPUT=$(forge create --rpc-url $RPC_URL --private-key $PRIV_KEY --broadcast src/SmartVault.sol:SmartVault --constructor-args $OWNER $AI_ADDR $V_ADDR 2>/dev/null)
VAULT_ADDR=$(echo "$VAULT_OUTPUT" | grep "Deployed to:" | awk '{print $3}')

echo -e "${GREEN}✅ Verifier Deployed: $V_ADDR${NC}"
echo -e "${GREEN}✅ Smart Vault Deployed: $VAULT_ADDR${NC}"

# Update Frontend Config
echo -e "
${BLUE}Step 5: Updating Configuration Files...${NC}"

# Update Vault Constants
cat <<EOF > "$PROJECT_ROOT/frontend/src/constants/vault.ts"
export const VAULT_ADDRESS = "$VAULT_ADDR";
export const VAULT_ABI = [
  "function hasHighIncomeBadge() view returns (bool)",
  "function owner() view returns (address)",
  "function verifyIncome(uint[2] a, uint[2][2] b, uint[2] c, uint[2] input) external",
  "function execute(address dest, uint256 value, bytes calldata func) external"
];
EOF

# Update API Route (Ensuring keys and addresses match)
cat <<EOF > "$PROJECT_ROOT/frontend/src/app/api/approve/route.ts"
import { NextResponse } from "next/server";
import { Groq } from "groq-sdk";
import { ethers } from "ethers";

export async function POST(req: Request) {
  try {
    const { txContext, userOpHash } = await req.json();
    const groq = new Groq({ apiKey: "$GROQ_KEY" });
    const aiPrivateKey = "$AI_PRIV_KEY";
    const wallet = new ethers.Wallet(aiPrivateKey);

    const completion = await groq.chat.completions.create({
      model: "llama-3.3-70b-versatile",
      messages: [
        { role: "system", content: "You are the LockedFI AI Guardian. Start with 'APPROVE' if safe." },
        { role: "user", content: txContext }
      ],
    });

    const decision = completion.choices[0].message.content || "";
    if (decision.includes("APPROVE")) {
      const signature = await wallet.signMessage(ethers.getBytes(userOpHash));
      return NextResponse.json({ approved: true, signature, decision });
    }
    return NextResponse.json({ approved: false, decision });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
EOF

echo -e "${GREEN}✅ Constants and API Routes updated.${NC}"

# Initial On-chain setup
echo -e "
${BLUE}Step 6: Initializing Vault State...${NC}"
# Grant high income badge for the demo
cast send --rpc-url $RPC_URL --private-key $PRIV_KEY $VAULT_ADDR "verifyIncome(uint256[2],uint256[2][2],uint256[2],uint256[2])" "[0,0]" "[[0,0],[0,0]]" "[0,0]" "[0,0]" > /dev/null 2>&1
# Fund the vault with 1 ETH
cast send --rpc-url $RPC_URL --private-key $PRIV_KEY $VAULT_ADDR --value 1ether > /dev/null 2>&1

echo -e "${GREEN}✅ Vault funded and Badge granted.${NC}"

# 5. Start Dashboard
echo -e "
${BLUE}Step 7: Launching User Dashboard...${NC}"
cd "$PROJECT_ROOT/frontend"
rm -rf .next

echo -e "${GREEN}✅ System is LIVE!${NC}"
echo -e "
${BLUE}================================================${NC}"
echo -e "🎯 ${GREEN}URL:${NC} http://localhost:$FRONTEND_PORT"
echo -e "🛡️  ${GREEN}AI Guardian Active${NC}"
echo -e "🔐 ${GREEN}ZK-Verification Enabled${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "Press ${RED}Ctrl+C${NC} to stop all services."

# Start frontend in foreground to keep script alive
npm run dev -- -p $FRONTEND_PORT
