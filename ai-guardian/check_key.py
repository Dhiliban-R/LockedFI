import os
from dotenv import load_dotenv

# Try to load the .env file explicitly from the current directory
load_dotenv(dotenv_path='./.env')

key = os.getenv("GROQ_API_KEY")

if key:
    print(f"Key Found! Starts with: {key[:7]}... Ends with: ...{key[-4:]}")
    print(f"Total Length: {len(key)} characters")
else:
    print("CRITICAL ERROR: No GROQ_API_KEY found in the environment.")
