// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGaiaVerifier {
    function verifyZKProof(bytes32 eegDataHash, uint256 result, bytes memory zkProof) external view returns (bool);
}

interface IEigenLayerStaking {
    function slash(address institution, uint256 amount) external;
    function getStake(address institution) external view returns (uint256);
    function reward(address institution, uint256 amount) external;
}

contract NeuroStake is Ownable {
    struct Computation {
        uint256 result;
        bytes zkProof;
        bool verified;
    }

    mapping(bytes32 => Computation) public computations;
    mapping(address => uint256) public institutionRewards;
    mapping(address => uint256) public buyerLockedFunds;

    IERC20 public eigenLayerToken;
    IGaiaVerifier public gaiaVerifier;
    IEigenLayerStaking public eigenLayerStaking;

    event RewardsDistributed(address indexed institution, uint256 amount);
    event PaymentReleased(address indexed buyer, address indexed institution, uint256 amount);
    event EigenLayerRewardComputed(address indexed institution, uint256 reward);

    constructor(address _eigenLayerToken, address _gaiaVerifier, address _eigenLayerStaking) {
        eigenLayerToken = IERC20(_eigenLayerToken);
        gaiaVerifier = IGaiaVerifier(_gaiaVerifier);
        eigenLayerStaking = IEigenLayerStaking(_eigenLayerStaking);
    }

    /**
     * @dev Distributes rewards to institutions that process verified EEG data.
     */
    function distributeRewards(address institution, uint256 amount) external onlyOwner {
        require(amount > 0, "Reward amount must be greater than zero.");
        require(eigenLayerToken.transfer(institution, amount), "Reward transfer failed.");

        institutionRewards[institution] += amount;

        emit RewardsDistributed(institution, amount);
    }

    /**
     * @dev Locks buyer funds for a computation request.
     */
    function lockPayment(address buyer, uint256 amount) external {
        require(eigenLayerToken.transferFrom(buyer, address(this), amount), "Payment lock failed.");
        buyerLockedFunds[buyer] += amount;
    }

    /**
     * @dev Releases payment to the institution after verification.
     */
    function releasePayment(address buyer, address institution, uint256 amount) external onlyOwner {
        require(buyerLockedFunds[buyer] >= amount, "Insufficient locked funds.");
        require(eigenLayerToken.transfer(institution, amount), "Payment transfer failed.");

        buyerLockedFunds[buyer] -= amount;

        emit PaymentReleased(buyer, institution, amount);
    }

    /**
     * @dev Computes EigenLayer rewards for institutions based on successful computations.
     */
    function computeEigenLayerReward(address institution) external {
        require(eigenLayerStaking.getStake(institution) > 0, "Institution has no stake.");

        uint256 baseReward = 10 * 1e18; // Example: 10 tokens per verified computation
        uint256 stakeMultiplier = eigenLayerStaking.getStake(institution) / 1e18;
        uint256 finalReward = baseReward * stakeMultiplier;

        eigenLayerStaking.reward(institution, finalReward);
        institutionRewards[institution] += finalReward;

        emit EigenLayerRewardComputed(institution, finalReward);
    }
}