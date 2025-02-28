const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Your Hardhat deployer address:", deployer.address);

  // Use 1RPC.io as the provider
  const { ethers: externalEthers } = require("ethers");
  const provider = new externalEthers.JsonRpcProvider("https://1rpc.io/holesky");

  // Fetch balance
  try {
    const balance = await provider.getBalance(deployer.address);
    console.log("Balance:", externalEthers.formatEther(balance), "ETH");
  } catch (error) {
    console.error("Failed to fetch balance:", error.message);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});