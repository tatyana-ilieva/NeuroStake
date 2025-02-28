require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with account:", deployer.address);

    // Load addresses from environment variables
    const eigenLayerToken = process.env.EIGENLAYER_TOKEN;
    const gaiaVerifier = process.env.GAIA_VERIFIER;
    const eigenLayerStaking = process.env.EIGENLAYER_STAKING;
    const avsDirectory = process.env.AVS_DIRECTORY;
    const rewardsCoordinator = process.env.REWARDS_COORDINATOR;
    const deployerFunds = process.env.DEPLOYER_FUNDS || "0";

    if (!eigenLayerToken || !gaiaVerifier || !eigenLayerStaking || !avsDirectory || !rewardsCoordinator) {
        throw new Error("❌ Missing required environment variables! Update your .env file.");
    }

    console.log("\n🔹 Deploying NeuroStake...");

    // Deploy NeuroStake contract
    const NeuroStake = await ethers.getContractFactory("NeuroStake");
    const neuroStake = await NeuroStake.deploy(
        eigenLayerToken,
        gaiaVerifier,
        eigenLayerStaking,
        { value: ethers.parseEther(deployerFunds) }
    );
    await neuroStake.waitForDeployment();
    console.log("✅ NeuroStake deployed at:", await neuroStake.getAddress());

    console.log("\n🔹 Deploying ComputationRegistry...");
    const ComputationRegistry = await ethers.getContractFactory("ComputationRegistry");
    const computationRegistry = await ComputationRegistry.deploy(gaiaVerifier);
    await computationRegistry.waitForDeployment();
    console.log("✅ ComputationRegistry deployed at:", await computationRegistry.getAddress());

    console.log("\n🔹 Deploying PrivateEEGDataRegistry...");
    const PrivateEEGDataRegistry = await ethers.getContractFactory("PrivateEEGDataRegistry");
    const privateEEGDataRegistry = await PrivateEEGDataRegistry.deploy();
    await privateEEGDataRegistry.waitForDeployment();
    console.log("✅ PrivateEEGDataRegistry deployed at:", await privateEEGDataRegistry.getAddress());

    console.log("\n🚀 All contracts deployed successfully!");

    // Verify contracts on Etherscan (optional)
    console.log("\n🔍 To verify contracts, run:");
    console.log(`npx hardhat verify --network <network> ${await neuroStake.getAddress()} ${eigenLayerToken} ${gaiaVerifier} ${eigenLayerStaking}`);
    console.log(`npx hardhat verify --network <network> ${await computationRegistry.getAddress()} ${gaiaVerifier}`);
    console.log(`npx hardhat verify --network <network> ${await privateEEGDataRegistry.getAddress()}`);
}

// Run deployment script
main().catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exitCode = 1;
});
