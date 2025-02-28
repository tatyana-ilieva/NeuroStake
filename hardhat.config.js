require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: "0.8.26",
  networks: {
    holesky: {
      url: "https://1rpc.io/holesky",
      chainId: 17000,
      accounts: [process.env.PRIVATE_KEY], // Make sure your private key is loaded
    },
  },
};