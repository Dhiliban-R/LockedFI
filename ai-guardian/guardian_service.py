import os
from web3 import Web3
from groq import Groq
from dotenv import load_dotenv
from eth_account import Account
from eth_account.messages import encode_defunct

# Force reload from the current directory to ensure we use the working key
load_dotenv(dotenv_path='./.env', override=True)

# Setup
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))
client = Groq(api_key=os.getenv('GROQ_API_KEY'))
ai_account = Account.from_key(os.getenv('PRIVATE_KEY'))
vault_address = '0x67d269191c92Caf3cD7723F116c85e6E9bf55933'

def get_transaction_history():
    # FETCH: Look at the last 100 blocks for withdrawal events
    try:
        logs = w3.eth.get_logs({
            'fromBlock': 0,
            'address': vault_address
        })
        return f'User has performed {len(logs)} successful transactions recently.'
    except Exception as e:
        return f'No prior transaction history found. (Error: {e})'

def get_ai_decision(context, history):
    full_prompt = f'HISTORY: {history}\nCURRENT REQUEST: {context}\nDecision: APPROVE or REJECT?'
    try:
        completion = client.chat.completions.create(
            model='llama-3.3-70b-versatile',
            messages=[
                {'role': 'system', 'content': 'You are the LockedFI AI Guardian. You now have access to user history. Analyze patterns.'},
                {'role': 'user', 'content': full_prompt}
            ],
            temperature=0
        )
        return completion.choices[0].message.content
    except Exception as e:
        return f"ERROR: {e}"
