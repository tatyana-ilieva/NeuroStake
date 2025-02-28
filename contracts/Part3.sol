// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IGaiaVerifier {
    function verifyZKProof(bytes32 eegDataHash, uint256 result, bytes memory zkProof) external view returns (bool);
}

contract ComputationRegistry is Ownable {
    struct Computation {
        uint256 result;
        bytes zkProof;
        bool verified;
    }

    mapping(bytes32 => Computation) public computations;
    IGaiaVerifier public gaiaVerifier;

    event ComputationResultStored(bytes32 indexed eegDataHash, uint256 result, bytes zkProof);
    event ComputationVerified(bytes32 indexed eegDataHash, bool success);

    constructor(address _gaiaVerifier) Ownable(msg.sender) {
        gaiaVerifier = IGaiaVerifier(_gaiaVerifier);
    }

    function storeComputation(bytes32 eegDataHash, uint256 result, bytes memory zkProof) external onlyOwner {
        require(computations[eegDataHash].result == 0, "Computation already stored.");

        computations[eegDataHash] = Computation({
            result: result,
            zkProof: zkProof,
            verified: false
        });

        emit ComputationResultStored(eegDataHash, result, zkProof);
    }

    function verifyComputation(bytes32 eegDataHash) external returns (bool) {
        require(computations[eegDataHash].result != 0, "Computation not found.");
        require(computations[eegDataHash].zkProof.length > 0, "ZK Proof not available.");

        bool success = gaiaVerifier.verifyZKProof(
            eegDataHash,
            computations[eegDataHash].result,
            computations[eegDataHash].zkProof
        );

        computations[eegDataHash].verified = success;
        emit ComputationVerified(eegDataHash, success);
        return success;
    }
}
