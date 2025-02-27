const hre = require("hardhat");

async function main() {
  const NeuroStake = await hre.ethers.getContractFactory("NeuroStake");
  const neuroStake = await NeuroStake.deploy("0xYourEigenLayerToken", "0xYourRewardsCoordinator");

  await neuroStake.deployed();
  console.log(`NeuroStake deployed to: ${neuroStake.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});