// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IAVSDirectory {
    function registerAVS(address avsOperator) external;
    function isOperatorRegistered(address operator) external view returns (bool);
}

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
    IAVSDirectory public avsDirectory;
    IRewardsCoordinator public rewardsCoordinator;

    address public owner;
    uint256 public minStakeAmount = 1 ether;

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
    event FraudDetected(address indexed institution, bytes32 eegDataHash, uint256 slashedAmount);
    event Received(address sender, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyRegisteredOperator() {
        require(avsDirectory.isOperatorRegistered(msg.sender), "Operator not registered in AVS");
        _;
    }

    /// @notice Constructor is now payable, allowing ETH to be sent on deployment
    constructor(
        address _eigenLayerToken,
        address _avsDirectory,
        address _rewardsCoordinator
    ) payable {
        eigenLayerToken = IERC20(_eigenLayerToken);
        avsDirectory = IAVSDirectory(_avsDirectory);
        rewardsCoordinator = IRewardsCoordinator(_rewardsCoordinator);
        owner = msg.sender;
    }

    function registerAVS() external {
        require(!avsDirectory.isOperatorRegistered(msg.sender), "Already registered");
        avsDirectory.registerAVS(msg.sender);
    }

    function registerEEGData(bytes32 eegDataHash, string memory metadata, bytes memory signature) external onlyRegisteredOperator {
        require(eegRecords[eegDataHash].institution == address(0), "EEG data already registered");
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

    function stakeEigenLayerTokens(uint256 amount) external onlyRegisteredOperator {
        require(amount >= minStakeAmount, "Stake amount too low");
        require(eegRecords[keccak256(abi.encodePacked(msg.sender))].institution == msg.sender, "Institution not registered");

        eigenLayerToken.transferFrom(msg.sender, address(this), amount);
        stakes[msg.sender] += amount;
        eegRecords[keccak256(abi.encodePacked(msg.sender))].stakeAmount = amount;

        rewardsCoordinator.createAVSRewardsSubmission(address(this), msg.sender, amount);

        emit Staked(msg.sender, amount);
    }

    function storeEEGMetadata(bytes32 eegDataHash, string memory metadata) external {
        require(eegRecords[eegDataHash].institution == msg.sender, "Unauthorized");

        eegRecords[eegDataHash].metadata = metadata;
        emit MetadataStored(eegDataHash, metadata);
    }

    function verifyInstitutionSignature(
        bytes32 eegDataHash,
        bytes memory signature,
        address institutionPK
    ) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(eegDataHash));
        return ECDSA.recover(messageHash, signature) == institutionPK;
    }

    function slashStake(bytes32 eegDataHash, uint256 penaltyAmount) external onlyOwner {
        address institution = eegRecords[eegDataHash].institution;
        require(institution != address(0), "EEG data not found");

        uint256 stakedAmount = stakes[institution];
        require(stakedAmount >= penaltyAmount, "Not enough stake to slash");

        stakes[institution] -= penaltyAmount;
        rewardsCoordinator.slashStake(institution, penaltyAmount);

        emit FraudDetected(institution, eegDataHash, penaltyAmount);
    }

    /// @notice Allows contract to receive ETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice Owner can withdraw ETH from contract
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
        emit Withdrawn(owner, amount);
    }
}