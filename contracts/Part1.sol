// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IRewardsCoordinator {
    function createAVSRewardsSubmission(
        address avs,
        address institution,
        uint256 amount
    ) external;

    function slashStake(address institution, uint256 amount) external;
}

contract NeuroStake {
    using ECDSA for bytes32;

    IERC20 public eigenLayerToken;
    IRewardsCoordinator public rewardsCoordinator;

    address public owner;
    uint256 public minStakeAmount = 1 ether; // Minimum stake amount required

    struct EEGData {
        bytes32 eegDataHash;
        string metadata;
        address institution;
        uint256 stakeAmount;
        bool verified;
    }

    mapping(bytes32 => EEGData) public eegRecords;
    mapping(address => uint256) public stakes;

    event EEGDataRegistered(address indexed institution, bytes32 indexed eegDataHash, string metadata);
    event Staked(address indexed institution, uint256 amount);
    event MetadataStored(bytes32 indexed eegDataHash, string metadata);
    event VerifiedSignature(bytes32 indexed eegDataHash, address indexed institution);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _eigenLayerToken, address _rewardsCoordinator) {
        eigenLayerToken = IERC20(_eigenLayerToken);
        rewardsCoordinator = IRewardsCoordinator(_rewardsCoordinator);
        owner = msg.sender;
    }

    /**
     * @dev Registers EEG data and verifies its authenticity
     */
    function registerEEGData(bytes32 eegDataHash, string memory metadata, bytes memory signature) external {
        require(eegRecords[eegDataHash].institution == address(0), "EEG data already registered");
        
        // Verify the signature to ensure authenticity
        require(verifyInstitutionSignature(eegDataHash, signature, msg.sender), "Invalid signature");

        eegRecords[eegDataHash] = EEGData({
            eegDataHash: eegDataHash,
            metadata: metadata,
            institution: msg.sender,
            stakeAmount: 0,
            verified: false
        });

        emit EEGDataRegistered(msg.sender, eegDataHash, metadata);
    }

    /**
     * @dev Allows institutions to stake EigenLayer tokens
     */
    function stakeEigenLayerTokens(uint256 amount) external {
        require(amount >= minStakeAmount, "Stake amount too low");
        require(eegRecords[keccak256(abi.encodePacked(msg.sender))].institution == msg.sender, "Institution not registered");

        eigenLayerToken.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] += amount;
        eegRecords[keccak256(abi.encodePacked(msg.sender))].stakeAmount = amount;

        // Notify EigenLayer's RewardsCoordinator
        rewardsCoordinator.createAVSRewardsSubmission(address(this), msg.sender, amount);

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Stores EEG metadata on-chain
     */
    function storeEEGMetadata(bytes32 eegDataHash, string memory metadata) external {
        require(eegRecords[eegDataHash].institution == msg.sender, "Unauthorized");

        eegRecords[eegDataHash].metadata = metadata;
        emit MetadataStored(eegDataHash, metadata);
    }

    /**
     * @dev Verifies an institution's signature
     */
    function verifyInstitutionSignature(bytes32 eegDataHash, bytes memory signature, address institutionPK) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(eegDataHash));
        return messageHash.toEthSignedMessageHash().recover(signature) == institutionPK;
    }
}