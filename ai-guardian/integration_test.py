import os
from web3 import Web3
from eth_account import Account
from eth_account.messages import encode_defunct
from dotenv import load_dotenv

# Use override=True to ensure we pick up the local .env
load_dotenv(dotenv_path='./.env', override=True)

# 1. Setup Connection to Anvil
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
# Use the address from the constants or a mock one for the script
vault_address = "0x67d269191c92Caf3cD7723F116c85e6E9bf55933"

# 2. Identities
owner_pv_key = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
ai_pv_key = os.getenv("PRIVATE_KEY")

# 3. Create a mock UserOperation Hash (The 'check' to be signed)
mock_user_op_hash = w3.keccak(text="locked_fi_test_v1")
message = encode_defunct(hexstr=mock_user_op_hash.hex())

# 4. Generate Dual Signature
owner_sig = Account.sign_message(message, private_key=owner_pv_key).signature
ai_sig = Account.sign_message(message, private_key=ai_pv_key).signature
bundled_sig = owner_sig + ai_sig

print(f"Bundled Signature Generated: {bundled_sig.hex()[:20]}...")

# 5. Call the Smart Contract to verify
# Standardized ERC-4337 v0.6 ABI
vault_abi = [
    {
        "inputs": [
            {
                "components": [
                    {"internalType": "address", "name": "sender", "type": "address"},
                    {"internalType": "uint256", "name": "nonce", "type": "uint256"},
                    {"internalType": "bytes", "name": "initCode", "type": "bytes"},
                    {"internalType": "bytes", "name": "callData", "type": "bytes"},
                    {"internalType": "uint256", "name": "callGasLimit", "type": "uint256"},
                    {"internalType": "uint256", "name": "verificationGasLimit", "type": "uint256"},
                    {"internalType": "uint256", "name": "preVerificationGas", "type": "uint256"},
                    {"internalType": "uint256", "name": "maxFeePerGas", "type": "uint256"},
                    {"internalType": "uint256", "name": "maxPriorityFeePerGas", "type": "uint256"},
                    {"internalType": "bytes", "name": "paymasterAndData", "type": "bytes"},
                    {"internalType": "bytes", "name": "signature", "type": "bytes"}
                ],
                "internalType": "struct UserOperation",
                "name": "userOp",
                "type": "tuple"
            },
            {"internalType": "bytes32", "name": "userOpHash", "type": "bytes32"},
            {"internalType": "uint256", "name": "missingAccountFunds", "type": "uint256"}
        ],
        "name": "validateUserOp",
        "outputs": [{"internalType": "uint256", "name": "validationData", "type": "uint256"}],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]

vault_contract = w3.eth.contract(address=vault_address, abi=vault_abi)

# Mock UserOperation
mock_user_op = {
    "sender": vault_address,
    "nonce": 0,
    "initCode": b"",
    "callData": b"",
    "callGasLimit": 0,
    "verificationGasLimit": 0,
    "preVerificationGas": 0,
    "maxFeePerGas": 0,
    "maxPriorityFeePerGas": 0,
    "paymasterAndData": b"",
    "signature": bundled_sig
}

# EntryPoint address to impersonate for the call
entry_point = "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789"

print("Simulating signature verification via Smart Vault...")
try:
    # Use call to simulate as we only want to verify the logic
    result = vault_contract.functions.validateUserOp(
        mock_user_op, 
        mock_user_op_hash, 
        0
    ).call({'from': entry_point})

    if result == 0:
        print("✅ SUCCESS: The Smart Vault accepted the AI-Co-signed transaction!")
    else:
        print(f"❌ FAILED: The Smart Vault rejected the signature (Result: {result}).")
except Exception as e:
    print(f"❌ ERROR: Transaction simulation failed: {e}")
