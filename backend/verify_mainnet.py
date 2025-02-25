import json
from web3 import Web3
import os
from dotenv import load_dotenv

load_dotenv()

# Load hash fingerprint
with open("eeg_fingerprint.json") as f:
    fingerprint_data = json.load(f)

# Connect to Ethereum mainnet
MAINNET_RPC_URL = os.getenv("ETHEREUM_RPC_URL")
web3_mainnet = Web3(Web3.HTTPProvider(MAINNET_RPC_URL))

# Load Mainnet contract
mainnet_contract_address = "0xYourMainnetContractAddress"
abi = [...]  # Load ABI of mainnet contract
contract = web3_mainnet.eth.contract(address=mainnet_contract_address, abi=abi)

# Store EEG hash on Ethereum
tx_hash = contract.functions.storeEEGHash(fingerprint_data["hash"]).transact(
    {"from": web3_mainnet.eth.accounts[0]}
)
web3_mainnet.eth.wait_for_transaction_receipt(tx_hash)

print(f"EEG Hash Stored on Ethereum, TX Hash: {tx_hash.hex()}")

# 🔹 Retrieve stored hash from Ethereum & verify
stored_hash = contract.functions.getEEGHash("0xYourWalletAddress").call()

if stored_hash == fingerprint_data["hash"]:
    print("✅ EEG Data is verified!")
else:
    print("❌ EEG Data does NOT match!")