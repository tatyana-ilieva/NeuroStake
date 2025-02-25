// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EEGVerification {
    mapping(address => string) public eegHashes;

    event EEGVerified(address indexed user, string hash);

    function storeEEGHash(string memory _hash) public {
        eegHashes[msg.sender] = _hash;
        emit EEGVerified(msg.sender, _hash);
    }

    function getEEGHash(address _user) public view returns (string memory) {
        return eegHashes[_user];
    }
}