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
}

contract NeuroStake is Ownable {
    struct Computation {
        uint256 result;
        bytes zkProof;
        bool verified;
    }

    mapping(bytes32 => Computation) public computations;
    mapping(address => bool) public slashedInstitutions;

    IERC20 public eigenLayerToken;
    IGaiaVerifier public gaiaVerifier;
    IEigenLayerStaking public eigenLayerStaking;

    event StakeSlashed(address indexed institution, uint256 amount);
    event FraudReported(bytes32 indexed eegDataHash, address indexed institution, bool fraudConfirmed);
    event InstitutionSlashed(address indexed institution);

    constructor(address _eigenLayerToken, address _gaiaVerifier, address _eigenLayerStaking) {
        eigenLayerToken = IERC20(_eigenLayerToken);
        gaiaVerifier = IGaiaVerifier(_gaiaVerifier);
        eigenLayerStaking = IEigenLayerStaking(_eigenLayerStaking);
    }

    /**
     * @dev Checks if an institution has been slashed for fraud.
     */
    function isInstitutionSlashed(address institution) external view returns (bool) {
        return slashedInstitutions[institution];
    }

    /**
     * @dev Reports a fraudulent EEG computation.
     * Calls Gaia AVS to verify the fraud and triggers slashing if needed.
     */
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

    /**
     * @dev Slashes an institution’s stake if fraud is detected.
     */
    function slashStake(address institution, uint256 penaltyAmount) internal {
        require(!slashedInstitutions[institution], "Institution already slashed.");
        require(eigenLayerStaking.getStake(institution) >= penaltyAmount, "Not enough stake to slash.");

        eigenLayerStaking.slash(institution, penaltyAmount); // Calls EigenLayer to execute slashing

        slashedInstitutions[institution] = true;

        emit StakeSlashed(institution, penaltyAmount);
        emit InstitutionSlashed(institution);
    }
}