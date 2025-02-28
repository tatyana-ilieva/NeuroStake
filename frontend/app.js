const contractAddress = "0x6e88094Cb9b2299B90BC5D08Dd5E695A8843fd58"; // Your contract address
const abiURL = "https://gist.githubusercontent.com/Lindsey-cyber/1b29c948f7bb1a6220e4a3642d5e632f/raw/9b9d46f84ecdcebcae3c1b8026f9b709cfeee725/gistfile1.txt";

let provider, signer, contract;
let contractABI;

// ✅ Fetch ABI first
async function loadABI() {
    try {
        const response = await fetch(abiURL);
        if (!response.ok) throw new Error("Failed to fetch ABI");
        contractABI = await response.json();
    } catch (error) {
        console.error("Error loading ABI:", error);
        alert("Could not load contract ABI.");
    }
}

// ✅ Connect MetaMask & initialize contract
async function connectWallet() {
    if (!window.ethereum) {
        alert("MetaMask is not installed!");
        return;
    }

    try {
        provider = new ethers.BrowserProvider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        signer = await provider.getSigner();

        if (!contractABI) await loadABI(); // Load ABI if not already loaded

        contract = new ethers.Contract(contractAddress, contractABI, signer);

        alert("Wallet Connected!");
        console.log("Connected Address:", await signer.getAddress());
    } catch (error) {
        console.error("MetaMask connection failed:", error);
    }
}

// ✅ Function to stake tokens (with validation)
async function stakeTokens() {
    if (!contract) {
        alert("Please connect your wallet first!");
        return;
    }

    try {
        console.log("Contract Instance:", contract);
        console.log("Signer Address:", await signer.getAddress());

        const amount = ethers.parseUnits("1", 18); // Staking 1 token
        const tx = await contract.stakeEigenLayerTokens(amount);
        await tx.wait();

        alert("Staking Successful!");
    } catch (error) {
        console.error("Transaction failed:", error);
        alert("Transaction failed. Check console for details.");
    }
}

// ✅ Auto-reconnect on page reload
window.addEventListener("load", async () => {
    await loadABI();
    const accounts = await window.ethereum.request({ method: "eth_accounts" });
    if (accounts.length > 0) connectWallet();
});

// ✅ Listen for MetaMask account change
window.ethereum?.on("accountsChanged", async (accounts) => {
    if (accounts.length > 0) connectWallet();
    else alert("MetaMask disconnected!");
});

// ✅ Event Listeners
document.getElementById("connectWallet").addEventListener("click", connectWallet);
document.getElementById("stakeTokens").addEventListener("click", stakeTokens);