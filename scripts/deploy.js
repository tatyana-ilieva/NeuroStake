const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contract with account:", deployer.address);

  // Addresses of required contracts
  const eigenLayerToken = "0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F"; // Replace with test token
  const avsDirectory = "0x055733000064333CaDDbC92763c58BF0192fFeBf"; // Replace if needed
  const rewardsCoordinator = "0x7750d328b314EfFa365A0402CcfD489B80B0adda"; // Replace if needed
  const gaiaVerifier = "0x.."; // Replace with actual GaiaVerifier contract address
  const eigenLayerStaking = "0x6e88094Cb9b2299B90BC5D08Dd5E695A8843fd58"; // Replace with EigenLayer Staking contract

  console.log("Deploying NeuroStake...");

  // Deploy NeuroStake contract
  const NeuroStake = await ethers.getContractFactory("NeuroStake");
  const neuroStake = await NeuroStake.deploy(
    eigenLayerToken,
    gaiaVerifier,
    eigenLayerStaking, 
    {
      value: ethers.parseEther("0.1"), // Initial funding if needed
    }
  );

  // Wait for deployment
  await neuroStake.waitForDeployment();

  // Log deployed contract address
  console.log("✅ NeuroStake deployed at:", await neuroStake.getAddress());

  // Verify contract on Etherscan (optional)
  console.log("\n🚀 Verifying contract...");
  console.log(`npx hardhat verify --network <network> ${await neuroStake.getAddress()} ${eigenLayerToken} ${gaiaVerifier} ${eigenLayerStaking}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});