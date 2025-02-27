const hre = require("hardhat");

async function main() {
  const NeuroStake = await hre.ethers.getContractFactory("NeuroStake");
  const neuroStake = await NeuroStake.deploy("0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F", "0x055733000064333CaDDbC92763c58BF0192fFeBf", "0x7750d328b314EfFa365A0402CcfD489B80B0adda");

  await neuroStake.deployed();
  console.log(`NeuroStake deployed to: ${neuroStake.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});