require("dotenv").config();
const hre = require("hardhat");

async function main() {
    const EEGStorageL2 = await hre.ethers.getContractFactory("EEGStorageL2");
    const eegContract = await EEGStorageL2.deploy();

    await eegContract.deployed();
    console.log("EEG Storage L2 deployed to:", eegContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});