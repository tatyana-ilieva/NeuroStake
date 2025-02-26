import json
import requests
import hashlib

# Pinata API for IPFS (You can also use Infura or Web3.Storage)
PINATA_API_KEY = "c66b81adabbd6993d67f"
PINATA_SECRET_API_KEY = "30491b3a859645a3c36ce99f04c0508091217a2d542daa1cbd05bf48f1cea5e6"

def upload_to_ipfs(file_path):
    """Uploads a file to IPFS via Pinata"""
    with open(file_path, "rb") as f:
        response = requests.post(
            "https://api.pinata.cloud/pinning/pinFileToIPFS",
            files={"file": f},
            headers={
                "pinata_api_key": PINATA_API_KEY,
                "pinata_secret_api_key": PINATA_SECRET_API_KEY,
            },
        )
    return response.json()["IpfsHash"]  # Returns IPFS CID

# Upload EEG files to IPFS
compressed_ipfs_cid = upload_to_ipfs("compressed_eeg.bin")
json_ipfs_cid = upload_to_ipfs("processed_eeg.json")

# Generate SHA-256 hash of the EEG binary
with open("compressed_eeg.bin", "rb") as f:
    eeg_binary_data = f.read()
eeg_hash = hashlib.sha256(eeg_binary_data).hexdigest()

# Create NFT metadata
metadata = {
    "name": "EEG Data NFT",
    "description": "Decentralized EEG data storage & verification.",
    "compressed_eeg_ipfs": f"https://ipfs.io/ipfs/{compressed_ipfs_cid}",
    "processed_eeg_ipfs": f"https://ipfs.io/ipfs/{json_ipfs_cid}",
    "hash": eeg_hash,
}

# Save NFT metadata to JSON
metadata_file = "eeg_metadata.json"
with open(metadata_file, "w") as f:
    json.dump(metadata, f)

# Upload NFT metadata to IPFS
metadata_ipfs_cid = upload_to_ipfs(metadata_file)

print(f"✅ EEG Metadata stored on IPFS: https://ipfs.io/ipfs/{metadata_ipfs_cid}")