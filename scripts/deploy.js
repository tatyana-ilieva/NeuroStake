const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contract with account:", deployer.address);

  const eigenLayerToken = "0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F"; // Replace with test token
  const avsDirectory = "0x055733000064333CaDDbC92763c58BF0192fFeBf"; // Replace if needed
  const rewardsCoordinator = "0x7750d328b314EfFa365A0402CcfD489B80B0adda"; // Replace if needed

  const NeuroStake = await ethers.getContractFactory("NeuroStake");
  const neuroStake = await NeuroStake.deploy(eigenLayerToken, avsDirectory, rewardsCoordinator, {
    value: ethers.parseEther("0.1"), // Initial funding if needed
  });

  // Wait for deployment (ethers.js v6 change)
  await neuroStake.waitForDeployment();

  // Use getAddress() instead of neuroStake.address
  console.log("NeuroStake deployed to:", await neuroStake.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});