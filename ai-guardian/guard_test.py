import os
from groq import Groq
from dotenv import load_dotenv

# Force reload from the current directory
load_dotenv(dotenv_path='./.env', override=True)

api_key = os.getenv("GROQ_API_KEY")
print(f"DEBUG: Using Key starting with: {api_key[:10]}...")

client = Groq(api_key=api_key)

transaction_context = """
User wants to withdraw 0.5 ETH. User HAS a ZK-Income Badge.
Decision: APPROVE or REJECT?
"""

try:
    completion = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": "You are the LockedFI AI Guardian."},
            {"role": "user", "content": transaction_context}
        ],
        temperature=0,
    )
    print("AI Guard Response:")
    print(completion.choices[0].message.content)
except Exception as e:
    print(f"Error: {e}")
