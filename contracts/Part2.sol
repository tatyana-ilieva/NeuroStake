// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NeuroStake {
    IERC20 public eigenLayerToken;

    address public owner;
    uint256 public verificationTimeLimit = 3 days; // Time limit before refunding buyer if verification fails

    struct ComputeRequest {
        bytes32 eegDataHash;
        address buyer;
        uint256 amount;
        bool isPaid;
        bool isVerified;
        uint256 timestamp;
    }

    mapping(address => ComputeRequest) public computeRequests;
    mapping(bytes32 => uint256) public lockedPayments;

    event ComputeAccessPurchased(address indexed buyer, bytes32 indexed eegDataHash, uint256 amount);
    event PaymentLocked(address indexed buyer, uint256 amount);
    event PaymentReleased(address indexed buyer, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _eigenLayerToken) {
        eigenLayerToken = IERC20(_eigenLayerToken);
        owner = msg.sender;
    }

    /**
     * @dev Allows a buyer to pay for EEG computation
     */
    function purchaseComputeAccess(bytes32 eegDataHash, uint256 amount, address buyer) external {
        require(amount > 0, "Payment must be greater than zero");
        require(computeRequests[buyer].amount == 0, "Existing compute request in process");

        // Transfer EigenLayer tokens from buyer to contract
        eigenLayerToken.transferFrom(buyer, address(this), amount);

        computeRequests[buyer] = ComputeRequest({
            eegDataHash: eegDataHash,
            buyer: buyer,
            amount: amount,
            isPaid: true,
            isVerified: false,
            timestamp: block.timestamp
        });

        emit ComputeAccessPurchased(buyer, eegDataHash, amount);
    }

    /**
     * @dev Locks buyer's payment until computation verification is complete
     */
    function lockPaymentUntilVerification(address buyer, uint256 amount) external {
        require(computeRequests[buyer].isPaid, "Payment not made");
        require(lockedPayments[computeRequests[buyer].eegDataHash] == 0, "Already locked");

        // Lock funds
        lockedPayments[computeRequests[buyer].eegDataHash] = amount;

        emit PaymentLocked(buyer, amount);
    }

    /**
     * @dev Releases payment after successful computation verification
     */
    function releasePayment(address buyer) external onlyOwner {
        require(computeRequests[buyer].isVerified, "Computation not verified");
        
        uint256 amount = computeRequests[buyer].amount;
        require(amount > 0, "No locked payment to release");

        // Transfer funds to the institution
        eigenLayerToken.transfer(computeRequests[buyer].buyer, amount);

        // Clean up records
        delete computeRequests[buyer];
        delete lockedPayments[computeRequests[buyer].eegDataHash];

        emit PaymentReleased(buyer, amount);
    }
}