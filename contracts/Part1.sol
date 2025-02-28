// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PrivateEEGDataRegistry is Ownable {
    struct EEGData {
        bytes32 eegDataHash;
        string encryptedDataLocation; // Encrypted IPFS Hash
        string licenseId;
        string deviceModel;
        uint256 samplingRate;
        address institution;
    }

    mapping(bytes32 => EEGData) public eegRecords;

    event EEGDataRegistered(bytes32 indexed eegDataHash, address indexed institution);

    constructor() Ownable(msg.sender) {}

    function registerEEGData(
        bytes32 eegDataHash,
        string memory encryptedDataLocation,
        string memory licenseId,
        string memory deviceModel,
        uint256 samplingRate
    ) external {
        require(eegRecords[eegDataHash].eegDataHash == bytes32(0), "EEG data already registered");

        eegRecords[eegDataHash] = EEGData({
            eegDataHash: eegDataHash,
            encryptedDataLocation: encryptedDataLocation,
            licenseId: licenseId,
            deviceModel: deviceModel,
            samplingRate: samplingRate,
            institution: msg.sender
        });

        emit EEGDataRegistered(eegDataHash, msg.sender);
    }

    function getEEGData(bytes32 eegDataHash) external view returns (EEGData memory) {
        require(eegRecords[eegDataHash].eegDataHash != bytes32(0), "EEG data not found");
        return eegRecords[eegDataHash];
    }
}
