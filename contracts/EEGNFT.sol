// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EEGNFT is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;
    mapping(uint256 => string) public eegHashes;  // EEG Data Hash for verification
    mapping(uint256 => address) public eegOwners; // Stores NFT Owners

    event EEGMinted(address indexed owner, uint256 tokenId, string ipfsCID, string hash);

    constructor() ERC721("EEGDataNFT", "EEGNFT") {}

    function mintEEGNFT(string memory _ipfsCID, string memory _hash) public {
        uint256 tokenId = nextTokenId;
        nextTokenId++;

        _safeMint(msg.sender, tokenId);  // Assigns NFT to uploader
        _setTokenURI(tokenId, _ipfsCID);

        eegHashes[tokenId] = _hash;
        eegOwners[tokenId] = msg.sender;

        emit EEGMinted(msg.sender, tokenId, _ipfsCID, _hash);
    }

    function getEEGData(uint256 tokenId) public view returns (string memory, string memory, address) {
        require(_exists(tokenId), "EEG NFT does not exist");
        return (tokenURI(tokenId), eegHashes[tokenId], eegOwners[tokenId]);
    }
}