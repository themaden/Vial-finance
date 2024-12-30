// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract LightProtocol is ReentrancyGuard, Ownable {
    IERC20 public token;

    struct PrivateTransaction {
        bytes32 commitment;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(uint256 => bytes32) public merkleRoots;
    mapping(bytes32 => bool) public nullifiers;
    mapping(address => uint256) public userDeposits;

    uint256 public constant MIN_DEPOSIT = 1e15; // 0.001 token
    uint256 public constant MAX_DEPOSIT = 1e21; // 1000 tokens
    uint256 public currentRootIndex;
    uint256 public constant MERKLE_TREE_HEIGHT = 20;
    uint256 public totalDeposits;

    event Deposit(bytes32 indexed commitment, uint256 leafIndex, uint256 timestamp);
    event Withdrawal(address indexed recipient, bytes32 indexed nullifier, uint256 amount, uint256 timestamp);
    event NewMerkleRoot(uint256 indexed index, bytes32 root);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(bytes32 _commitment, uint256 _amount) external nonReentrant {
        require(_commitment != bytes32(0), "Invalid commitment");
        require(_amount >= MIN_DEPOSIT && _amount <= MAX_DEPOSIT, "Invalid amount");

        uint256 leafIndex =
            uint256(keccak256(abi.encodePacked(_commitment, block.timestamp))) % (2 ** MERKLE_TREE_HEIGHT);

        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        userDeposits[msg.sender] += _amount;
        totalDeposits += _amount;

        emit Deposit(_commitment, leafIndex, block.timestamp);
    }

    function withdraw(bytes32 _nullifier, address _recipient, uint256 _amount, bytes32[] calldata _merkleProof)
        external
        nonReentrant
    {
        require(!nullifiers[_nullifier], "Nullifier has already been used");
        require(_amount >= MIN_DEPOSIT && _amount <= MAX_DEPOSIT, "Invalid amount");
        require(
            MerkleProof.verify(_merkleProof, merkleRoots[currentRootIndex], keccak256(abi.encodePacked(_nullifier))),
            "Invalid Merkle proof"
        );

        nullifiers[_nullifier] = true;
        require(token.transfer(_recipient, _amount), "Transfer failed");

        totalDeposits -= _amount;

        emit Withdrawal(_recipient, _nullifier, _amount, block.timestamp);
    }

    function updateMerkleRoot(bytes32 _newRoot) external onlyOwner {
        currentRootIndex++;
        merkleRoots[currentRootIndex] = _newRoot;
        emit NewMerkleRoot(currentRootIndex, _newRoot);
    }

    function verifyZKProof(uint256[8] calldata _proof, uint256[2] calldata _input) external pure returns (bool) {
        // Bu fonksiyon, gerçek bir ZK-SNARK doğrulayıcısı ile değiştirilmelidir
        // Şu an sadece örnek amaçlı basit bir kontrol yapıyor
        return _proof[0] != 0 && _input[0] != 0;
    }

    function getUserDeposit(address _user) external view returns (uint256) {
        return userDeposits[_user];
    }

    function getTotalDeposits() external view returns (uint256) {
        return totalDeposits;
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "Emergency shot failed");
    }
}
