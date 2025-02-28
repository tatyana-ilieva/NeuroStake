const contractAddress = "0x6e88094Cb9b2299B90BC5D08Dd5E695A8843fd58"; // Your deployed contract address
const abiURL = "https://gist.githubusercontent.com/Lindsey-cyber/1b29c948f7bb1a6220e4a3642d5e632f/raw/9b9d46f84ecdcebcae3c1b8026f9b709cfeee725/gistfile1.txt";

let provider;
let signer;
let contract;

// ✅ Function to fetch ABI from GitHub Gist
async function loadABI() {
    try {
        const response = await fetch(abiURL);
        if (!response.ok) throw new Error("Failed to fetch ABI");

        const abi = await response.json();
        console.log("Loaded ABI:", abi); // ✅ Debugging log
        return abi;
    } catch (error) {
        console.error("Error loading ABI:", error);
        alert("Failed to load contract ABI.");
    }
}

// ✅ Function to connect MetaMask & check if the user is logged in
async function connectWallet() {
    if (!window.ethereum) {
        alert("MetaMask is not installed!");
        return;
    }

    try {
        // 🔹 Request MetaMask connection
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        if (!accounts.length) {
            alert("No accounts found.");
            return;
        }

        // 🔹 Create Ethers provider & signer
        provider = new ethers.BrowserProvider(window.ethereum);
        signer = await provider.getSigner();
        console.log("Signer address:", await signer.getAddress());

        // 🔹 Load ABI dynamically
        const contractABI = await loadABI();
        if (!contractABI) {
            alert("Could not load ABI.");
            return;
        }

        // 🔹 Initialize contract instance
        contract = new ethers.Contract(contractAddress, contractABI, signer);
        console.log("Contract initialized:", contract);

        alert("Wallet Connected!");
        console.log("Connected Address:", accounts[0]);
    } catch (error) {
        console.error("MetaMask connection failed:", error);
    }
}

// ✅ Function to check if the wallet is already connected
async function checkConnection() {
    try {
        const sender = await window.ethereum.request({ method: "eth_accounts" });
        if (!sender.length) {
            return `<Web3Connect connectLabel="Connect with Web3" />`;
        }
        console.log("Wallet already connected:", sender[0]);
    } catch (error) {
        console.error("Error checking wallet connection:", error);
    }
}

// ✅ Function to stake tokens
async function stakeTokens() {
    if (!contract) {
        alert("Please connect your wallet first!");
        console.error("Contract is not initialized!");
        await connectWallet();
    }

    try {
        console.log("Staking with contract:", contract);
        const amount = ethers.parseUnits("1", 18); // Staking 1 token
        const tx = await contract.stakeEigenLayerTokens(amount);
        await tx.wait();
        alert("Staking Successful!");
    } catch (error) {
        console.error("Transaction failed:", error);
        alert("Transaction failed. Check console for details.");
    }
}

// ✅ Listen for MetaMask Account Changes
window.ethereum?.on("accountsChanged", async (accounts) => {
    if (!accounts.length) {
        alert("MetaMask disconnected!");
        return;
    }
    console.log("MetaMask account changed:", accounts[0]);
    connectWallet(); // Reconnect if account changes
});

// ✅ Attach event listeners
document.getElementById("connectWallet").addEventListener("click", connectWallet);
document.getElementById("stakeTokens").addEventListener("click", stakeTokens);

// ✅ Run check on page load
checkConnection();