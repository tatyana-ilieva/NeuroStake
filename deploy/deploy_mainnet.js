require("dotenv").config();
const hre = require("hardhat");

async function main() {
    const EEGVerification = await hre.ethers.getContractFactory("EEGVerification");
    const eegContract = await EEGVerification.deploy();

    await eegContract.deployed();
    console.log("EEG Verification Contract deployed to:", eegContract.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});