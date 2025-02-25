import json
import zlib
import hashlib
from web3 import Web3
import os
from dotenv import load_dotenv

load_dotenv()

# Load .mat EEG data and compress it
compressed_eeg_data = zlib.compress(open("eeg_data.mat", "rb").read())

# Generate hash for verification
hash_fingerprint = hashlib.sha256(compressed_eeg_data).hexdigest()

# Connect to L2 blockchain (Arbitrum RPC)
L2_RPC_URL = os.getenv("ARBITRUM_RPC_URL")
web3 = Web3(Web3.HTTPProvider(L2_RPC_URL))

# Load L2 contract
contract_address = "0xYourL2ContractAddress"
abi = [...]  # Load the compiled contract ABI
contract = web3.eth.contract(address=contract_address, abi=abi)

# Upload EEG data
tx_hash = contract.functions.uploadEEG(compressed_eeg_data, hash_fingerprint).transact(
    {"from": web3.eth.accounts[0]}
)
web3.eth.wait_for_transaction_receipt(tx_hash)

print(f"EEG Data Uploaded to L2, TX Hash: {tx_hash.hex()}")