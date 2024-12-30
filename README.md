# LightProtocol

LightProtocol is a privacy-focused transaction platform. This smart contract enables private transactions using ERC-20 tokens through a Merkle tree-based system. Users can privately deposit and withdraw their tokens.

## Key Features

- **Deposit and Withdrawal Operations**: Users can deposit a specific amount of tokens privately and later withdraw them with Merkle tree-based verification.
- **Merkle Tree**: A Merkle tree structure is used for private transactions.
- **Nullifier Tracking**: Each transaction is tracked with a nullifier to prevent reuse.
- **Reentrancy Protection**: The contract is protected against reentrancy attacks.
- **Owner Control**: Merkle tree roots can only be updated by the contract owner.

## Requirements

- Solidity ^0.8.17
- OpenZeppelin Contracts

## Usage

### 1. Deployment
Before deploying the contract to an Ethereum network, specify an ERC-20 token address as a constructor parameter:

```solidity
constructor(address _token) {
    token = IERC20(_token);
}
```

### 2. Deposit Operation
Users can call the `deposit` function to deposit their tokens. The minimum and maximum deposit amounts are as follows:

- Minimum Deposit: 0.001 token
- Maximum Deposit: 1000 tokens

#### Example:
```solidity
function deposit(bytes32 _commitment, uint256 _amount) external;
```
**Parameters:**
- `_commitment`: A hash representing the user's private transaction.
- `_amount`: The amount of tokens to be deposited.

### 3. Withdrawal Operation
Users can call the `withdraw` function to withdraw their deposited tokens. The withdrawal process includes Merkle tree verification.

#### Example:
```solidity
function withdraw(bytes32 _nullifier, address _recipient, uint256 _amount, bytes32[] calldata _merkleProof) external;
```
**Parameters:**
- `_nullifier`: A unique value used in the withdrawal process.
- `_recipient`: The address to receive the tokens.
- `_amount`: The amount of tokens to withdraw.
- `_merkleProof`: Proofs used for Merkle tree verification.

### 4. Update Merkle Root
The contract owner can update the Merkle tree root using the `updateMerkleRoot` function.

#### Example:
```solidity
function updateMerkleRoot(bytes32 _newRoot) external onlyOwner;
```

### 5. Emergency Withdrawal
The contract owner can withdraw all tokens in emergencies.

#### Example:
```solidity
function emergencyWithdraw() external onlyOwner;
```

## Events

- **Deposit**: Triggered when a deposit operation is successful.
  ```solidity
  event Deposit(bytes32 indexed commitment, uint256 leafIndex, uint256 timestamp);
  ```

- **Withdrawal**: Triggered when a withdrawal operation is successful.
  ```solidity
  event Withdrawal(address indexed recipient, bytes32 indexed nullifier, uint256 amount, uint256 timestamp);
  ```

- **NewMerkleRoot**: Triggered when a new Merkle root is set.
  ```solidity
  event NewMerkleRoot(uint256 indexed index, bytes32 root);
  ```

## Security Notes

1. **Reentrancy Protection**: The contract is protected against reentrancy attacks using the `nonReentrant` modifier.
2. **Nullifier Usage**: Nullifiers are tracked to prevent reuse.
3. **Emergency Mechanism**: A mechanism is in place to withdraw all funds in emergencies.

## Development
This contract includes a `verifyZKProof` function for potential future ZK-SNARK verification integration. Currently, it provides a basic validation example and should be replaced with a real ZK-SNARK verification mechanism.

```solidity
function verifyZKProof(uint256[8] calldata _proof, uint256[2] calldata _input) external pure returns (bool);
```

## License

This project is licensed under the MIT License. For more information, see the `LICENSE` file.

``
