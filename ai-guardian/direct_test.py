from groq import Groq

# PASTE YOUR NEW KEY DIRECTLY BELOW
client = Groq(api_key="gsk_PASTE_YOUR_NEW_KEY_HERE")

try:
    completion = client.chat.completions.create(
        model="llama3-8b-8192",
        messages=[{"role": "user", "content": "Say 'Guard Active'"}],
    )
    print(completion.choices[0].message.content)
except Exception as e:
    print(f"Error: {e}")
