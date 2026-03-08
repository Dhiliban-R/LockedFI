import os
from groq import Groq
from dotenv import load_dotenv
from eth_account import Account
from eth_account.messages import encode_defunct

# Force reload from the current directory to ensure we use the working key
load_dotenv(dotenv_path='./.env', override=True)

# 1. Setup AI and Blockchain tools
api_key = os.getenv("GROQ_API_KEY")
print(f"DEBUG: AI Guard using key starting with: {api_key[:10]}...")

client = Groq(api_key=api_key)
ai_private_key = os.getenv("PRIVATE_KEY")
ai_account = Account.from_key(ai_private_key)

print(f"AI Guardian Address: {ai_account.address}")

def get_ai_decision(context):
    try:
        completion = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": "You are the LockedFI AI Guardian. If a transaction is safe, start your response with the word 'APPROVE'. If not, start with 'REJECT'."},
                {"role": "user", "content": context}
            ],
            temperature=0,
        )
        return completion.choices[0].message.content
    except Exception as e:
        return f"ERROR: {e}"

def sign_transaction_hash(tx_hash_hex):
    # This is the 'Digital Pen' action
    message = encode_defunct(hexstr=tx_hash_hex)
    signed_message = Account.sign_message(message, private_key=ai_private_key)
    return signed_message.signature.hex()

# --- MOCK TEST CASE ---
mock_tx_context = "User withdrawing 0.05 ETH. This is below the risk limit. User has ZK-Badge."
mock_tx_hash = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

print("\nEvaluating Transaction...")
decision = get_ai_decision(mock_tx_context)
print(f"AI Decision: {decision[:20]}...")

if "APPROVE" in decision.upper():
    print("Action: AI is signing the transaction...")
    signature = sign_transaction_hash(mock_tx_hash)
    print(f"AI Signature: {signature}")
else:
    print(f"Action: AI REJECTED. Reasoning: {decision}")
