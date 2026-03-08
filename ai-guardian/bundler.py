import os
from eth_account import Account
from eth_account.messages import encode_defunct
from dotenv import load_dotenv

load_dotenv(override=True)

# 1. Setup Identities
owner_private_key = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80" # Standard Foundry Dev Key
ai_private_key = os.getenv("PRIVATE_KEY")

owner_account = Account.from_key(owner_private_key)
ai_account = Account.from_key(ai_private_key)

print(f"Owner Address: {owner_account.address}")
print(f"AI Guardian Address: {ai_account.address}")

# 2. The Transaction Hash (The 'Check' to be signed)
tx_hash_hex = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
message = encode_defunct(hexstr=tx_hash_hex)

# 3. Step 1: Owner Signs
owner_sig = Account.sign_message(message, private_key=owner_private_key)
print(f"\nOwner Signature (65 bytes): {owner_sig.signature.hex()}")

# 4. Step 2: AI Signs (Simulating the AI decision we built in Milestone 3.3)
ai_sig = Account.sign_message(message, private_key=ai_private_key)
print(f"AI Signature (65 bytes): {ai_sig.signature.hex()}")

# 5. Step 3: Bundle them into the 130-byte LockedFI Signature
# In Solidity: signature[0:65] is Owner, signature[65:130] is AI
dual_signature = owner_sig.signature + ai_sig.signature
print(f"\nFINAL BUNDLED SIGNATURE (130 bytes):")
print(dual_signature.hex())

print(f"\nTotal Length: {len(dual_signature)} bytes")
