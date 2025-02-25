// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EEGStorageL2 {
    mapping(address => bytes) private eegData;
    mapping(address => string) public eegHashes;

    event EEGUploaded(address indexed user, string hash);

    function uploadEEG(bytes memory _data, string memory _hash) public {
        eegData[msg.sender] = _data;
        eegHashes[msg.sender] = _hash;
        emit EEGUploaded(msg.sender, _hash);
    }

    function getEEGHash(address _user) public view returns (string memory) {
        return eegHashes[_user];
    }

    function getEEGData(address _user) public view returns (bytes memory) {
        require(bytes(eegHashes[_user]).length > 0, "No EEG data found");
        return eegData[_user];
    }
}