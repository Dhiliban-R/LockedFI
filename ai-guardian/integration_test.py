import os
from web3 import Web3
from eth_account import Account
from eth_account.messages import encode_defunct
from dotenv import load_dotenv

# Use override=True to ensure we pick up the local .env
load_dotenv(dotenv_path='./.env', override=True)

# 1. Setup Connection to Anvil
w3 = Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))
vault_address = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"

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
# We use 'call' because validateUserOp is a view function in our contract
vault_abi = [
    {
        "inputs": [
            {"internalType": "bytes32", "name": "userOpHash", "type": "bytes32"},
            {"internalType": "bytes", "name": "signature", "type": "bytes"}
        ],
        "name": "validateUserOp",
        "outputs": [{"internalType": "uint256", "name": "validationData", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    }
]

vault_contract = w3.eth.contract(address=vault_address, abi=vault_abi)

print("Sending signature to Smart Vault for verification...")
result = vault_contract.functions.validateUserOp(mock_user_op_hash, bundled_sig).call()

if result == 0:
    print("✅ SUCCESS: The Smart Vault accepted the AI-Co-signed transaction!")
else:
    print("❌ FAILED: The Smart Vault rejected the signature.")
