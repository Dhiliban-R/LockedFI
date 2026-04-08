import os
import time
import json
from web3 import Web3
from web3.middleware import geth_poa_middleware
from eth_account import Account
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class AISentinel:
    def __init__(self, rpc_url, vault_address, sentinel_key):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.w3.middleware_onion.inject(geth_poa_middleware, layer=0)
        self.vault_address = Web3.to_checksum_address(vault_address)
        self.account = Account.from_key(sentinel_key)
        
        # Load Vault ABI (simplified for pause function)
        self.vault_abi = [
            {
                "inputs": [],
                "name": "pause",
                "outputs": [],
                "stateMutability": "external",
                "type": "function"
            },
            {
                "inputs": [],
                "name": "paused",
                "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
                "stateMutability": "view",
                "type": "function"
            }
        ]
        self.vault_contract = self.w3.eth.contract(address=self.vault_address, abi=self.vault_abi)

    def is_malicious(self, tx):
        """
        AI-driven anomaly detection logic.
        In production, this would use a machine learning model to analyze:
        - Transaction value
        - Gas price anomalies
        - Contract interaction patterns (e.g., flash loan signatures)
        - Sender reputation
        """
        # PRODUCTION MOCK: Detect any transaction from a 'known bad' list or over a certain value
        # Or specifically, look for re-entrancy signatures in the callData
        if tx['to'] == self.vault_address and tx['value'] > Web3.to_wei(10, 'ether'):
            return True, "Extremely high value withdrawal detected"
        
        # Check for common attack signatures in input data (e.g., flash loans)
        if "0x" in tx.get('input', '') and len(tx['input']) > 1000:
            return True, "Possible complex exploit or flash loan detected"

        return False, "Normal"

    def trigger_kill_switch(self):
        """
        Autonomous action to pause the vault.
        """
        if self.vault_contract.functions.paused().call():
            print(f"[{time.ctime()}] Vault is already paused.")
            return

        print(f"[{time.ctime()}] !!! ATTACK DETECTED !!! Triggering Kill-Switch...")
        
        nonce = self.w3.eth.get_transaction_count(self.account.address)
        gas_price = self.w3.eth.gas_price * 2 # Front-run the attacker with higher gas price
        
        tx = self.vault_contract.functions.pause().build_transaction({
            'from': self.account.address,
            'nonce': nonce,
            'gas': 100000,
            'gasPrice': gas_price,
            'chainId': self.w3.eth.chain_id
        })
        
        signed_tx = self.w3.eth.account.sign_transaction(tx, self.account.key)
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
        print(f"[{time.ctime()}] Vault Paused. Transaction Hash: {tx_hash.hex()}")

    def monitor_mempool(self):
        """
        Listen for pending transactions in the mempool.
        """
        print(f"[{time.ctime()}] AI Sentinel Active. Monitoring Vault: {self.vault_address}")
        
        # Use a filter for pending transactions
        tx_filter = self.w3.eth.filter('pending')
        
        while True:
            try:
                for tx_hash in tx_filter.get_new_entries():
                    try:
                        tx = self.w3.eth.get_transaction(tx_hash)
                        if tx and tx['to'] == self.vault_address:
                            malicious, reason = self.is_malicious(tx)
                            if malicious:
                                print(f"[{time.ctime()}] ALERT: {reason}")
                                self.trigger_kill_switch()
                    except:
                        continue
                time.sleep(0.5) # Poll every 500ms
            except Exception as e:
                print(f"Error: {e}")
                time.sleep(1)

if __name__ == "__main__":
    # In a real environment, these would be in .env
    RPC_URL = "http://127.0.0.1:8545"
    VAULT_ADDR = "0x..." # To be filled after deployment
    SENTINEL_KEY = os.getenv("PRIVATE_KEY")
    
    sentinel = AISentinel(RPC_URL, VAULT_ADDR, SENTINEL_KEY)
    sentinel.monitor_mempool()
