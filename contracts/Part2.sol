// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGaiaVerifier {
    function verifyZKProof(bytes32 eegDataHash, uint256 result, bytes memory zkProof) external view returns (bool);
}

interface IEigenLayerStaking {
    function slash(address institution, uint256 amount) external;
    function getStake(address institution) external view returns (uint256);
    function reward(address institution, uint256 amount) external;
}

contract NeuroStake is Ownable(address(this)) {
    struct Computation {
        uint256 result;
        bytes zkProof;
        bool verified;
    }

    mapping(bytes32 => Computation) public computations;
    mapping(address => uint256) public buyerLockedFunds;
    mapping(address => bool) public slashedInstitutions;

    IERC20 public eigenLayerToken;
    IGaiaVerifier public gaiaVerifier;
    IEigenLayerStaking public eigenLayerStaking;

    event StakeSlashed(address indexed institution, uint256 amount);
    event FraudReported(bytes32 indexed eegDataHash, address indexed institution, bool fraudConfirmed);
    event InstitutionSlashed(address indexed institution);
    event RewardsDistributed(address indexed institution, uint256 amount);
    event PaymentReleased(address indexed buyer, address indexed institution, uint256 amount);
    event EigenLayerRewardComputed(address indexed institution, uint256 reward);

    constructor(address _eigenLayerToken, address _gaiaVerifier, address _eigenLayerStaking) {
        eigenLayerToken = IERC20(_eigenLayerToken);
        gaiaVerifier = IGaiaVerifier(_gaiaVerifier);
        eigenLayerStaking = IEigenLayerStaking(_eigenLayerStaking);
    }

    function reportFraud(bytes32 eegDataHash, address institution) external {
        require(computations[eegDataHash].result != 0, "Computation does not exist.");
        require(!slashedInstitutions[institution], "Institution is already slashed.");

        bool fraudDetected = !gaiaVerifier.verifyZKProof(
            eegDataHash,
            computations[eegDataHash].result,
            computations[eegDataHash].zkProof
        );

        emit FraudReported(eegDataHash, institution, fraudDetected);

        if (fraudDetected) {
            uint256 penaltyAmount = eigenLayerStaking.getStake(institution) / 2; // Slash 50% of stake
            slashStake(institution, penaltyAmount);
        }
    }

    function slashStake(address institution, uint256 penaltyAmount) internal {
        require(!slashedInstitutions[institution], "Institution already slashed.");
        require(eigenLayerStaking.getStake(institution) >= penaltyAmount, "Not enough stake to slash.");

        eigenLayerStaking.slash(institution, penaltyAmount);
        slashedInstitutions[institution] = true;

        emit StakeSlashed(institution, penaltyAmount);
        emit InstitutionSlashed(institution);
    }

    function distributeRewards(address institution, uint256 amount) external onlyOwner {
        require(amount > 0, "Reward amount must be greater than zero.");
        require(eigenLayerToken.transfer(institution, amount), "Reward transfer failed.");
        emit RewardsDistributed(institution, amount);
    }

    function lockPayment(address buyer, uint256 amount) external {
        require(eigenLayerToken.transferFrom(buyer, address(this), amount), "Payment lock failed.");
        buyerLockedFunds[buyer] += amount;
    }

    function releasePayment(address buyer, address institution, uint256 amount) external onlyOwner {
        require(buyerLockedFunds[buyer] >= amount, "Insufficient locked funds.");
        require(eigenLayerToken.transfer(institution, amount), "Payment transfer failed.");

        buyerLockedFunds[buyer] -= amount;

        emit PaymentReleased(buyer, institution, amount);
    }

    function computeEigenLayerReward(address institution) external {
        require(eigenLayerStaking.getStake(institution) > 0, "Institution has no stake.");

        uint256 baseReward = 10 * 1e18; // Example: 10 tokens per verified computation
        uint256 stakeMultiplier = eigenLayerStaking.getStake(institution) / 1e18;
        uint256 finalReward = baseReward * stakeMultiplier;

        eigenLayerStaking.reward(institution, finalReward);

        emit EigenLayerRewardComputed(institution, finalReward);
    }
}
