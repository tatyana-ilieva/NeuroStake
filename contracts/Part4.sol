// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IGaiaVerifier {
    function verifyZKProof(bytes32 eegDataHash, uint256 result, bytes memory zkProof) external view returns (bool);
}

contract NeuroStake is Ownable {
    struct Computation {
        uint256 result;
        bytes zkProof;
        bool verified;
    }

    mapping(bytes32 => Computation) public computations;

    event ComputationResultRetrieved(bytes32 indexed eegDataHash, uint256 result);
    event ZKProofRetrieved(bytes32 indexed eegDataHash, bytes zkProof);

    IGaiaVerifier public gaiaVerifier;

    constructor(address _gaiaVerifier) {
        gaiaVerifier = IGaiaVerifier(_gaiaVerifier);
    }

    /**
     * @dev Retrieves the computation result for a specific EEG data hash.
     */
    function getComputationResult(bytes32 eegDataHash) external view returns (uint256) {
        require(computations[eegDataHash].result != 0, "No computation result found.");
        return computations[eegDataHash].result;
    }

    /**
     * @dev Retrieves the ZK Proof for a specific EEG data hash.
     */
    function getZKProof(bytes32 eegDataHash) external view returns (bytes memory) {
        require(computations[eegDataHash].zkProof.length > 0, "No ZK proof found.");
        return computations[eegDataHash].zkProof;
    }

    /**
     * @dev Stores a new computation result and its associated ZK Proof.
     */
    function storeComputation(bytes32 eegDataHash, uint256 result, bytes memory zkProof) external onlyOwner {
        require(computations[eegDataHash].result == 0, "Computation already stored.");
        
        computations[eegDataHash] = Computation({
            result: result,
            zkProof: zkProof,
            verified: false
        });

        emit ComputationResultRetrieved(eegDataHash, result);
        emit ZKProofRetrieved(eegDataHash, zkProof);
    }

    /**
     * @dev Verifies the stored computation using Gaia's ZK Proof validation.
     */
    function verifyComputation(bytes32 eegDataHash) external returns (bool) {
        require(computations[eegDataHash].result != 0, "Computation not found.");
        require(computations[eegDataHash].zkProof.length > 0, "ZK Proof not available.");

        bool success = gaiaVerifier.verifyZKProof(
            eegDataHash,
            computations[eegDataHash].result,
            computations[eegDataHash].zkProof
        );

        if (success) {
            computations[eegDataHash].verified = true;
        }

        return success;
    }
}