require("dotenv").config();
const express = require("express");
const { ethers } = require("ethers");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const PORT = 3001;

// Contract & Network Configuration
const CONTRACT_ADDRESS = "0xYourContractAddress"; // Replace with deployed contract address
const PROVIDER_URL = "https://rpc.sepolia.org";  // Replace with actual EigenLayer RPC endpoint
const PRIVATE_KEY = process.env.PRIVATE_KEY; // Private key of admin for slashing
const provider = new ethers.JsonRpcProvider(PROVIDER_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

// Contract ABI (replace with actual ABI after deployment)
const CONTRACT_ABI = [
  "function stakeEEG(bytes32 eegDataHash) external payable",
  "function slashStake(bytes32 eegDataHash) external",
  "function withdrawStake() external",
  "function getStakeInfo(address institution) external view returns (tuple(uint256 amount, bytes32 eegDataHash, bool active))"
];

const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, wallet);

// Endpoint: Stake EEG Data
app.post("/stake", async (req, res) => {
    try {
        const { institution, eegDataHash, amount } = req.body;

        const tx = await contract.stakeEEG(eegDataHash, { value: ethers.parseEther(amount) });
        await tx.wait();

        res.json({ success: true, txHash: tx.hash });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Endpoint: Slash Stake (Admin Only)
app.post("/slash", async (req, res) => {
    try {
        const { eegDataHash } = req.body;

        const tx = await contract.slashStake(eegDataHash);
        await tx.wait();

        res.json({ success: true, txHash: tx.hash });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Endpoint: Withdraw Stake
app.post("/withdraw", async (req, res) => {
    try {
        const { institution } = req.body;
        
        const tx = await contract.connect(wallet).withdrawStake();
        await tx.wait();

        res.json({ success: true, txHash: tx.hash });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: error.message });
    }
});

// Endpoint: Get Stake Info
app.get("/stake/:institution", async (req, res) => {
    try {
        const { institution } = req.params;

        const stakeInfo = await contract.getStakeInfo(institution);
        res.json({
            amount: ethers.formatEther(stakeInfo.amount),
            eegDataHash: stakeInfo.eegDataHash,
            active: stakeInfo.active
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: error.message });
    }
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});