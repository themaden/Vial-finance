// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/Vial.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock", "MCK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

contract LightProtocolTest is Test {
    event Deposit(bytes32 indexed commitment, uint256 leafIndex, uint256 timestamp);
    event Withdrawal(address indexed recipient, bytes32 indexed nullifier, uint256 amount, uint256 timestamp);
    event NewMerkleRoot(uint256 indexed index, bytes32 root);

    LightProtocol public protocol;
    MockToken public token;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        token = new MockToken();
        protocol = new LightProtocol(address(token));

        token.transfer(user1, 1000 * 10 ** 18);
        token.transfer(user2, 1000 * 10 ** 18);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        bytes32 commitment = keccak256("commitment1");
        uint256 amount = 1 * 10 ** 18;

        token.approve(address(protocol), amount);

        uint256 expectedLeafIndex = uint256(keccak256(abi.encodePacked(commitment, block.timestamp))) % (2 ** 20);

        vm.expectEmit(true, false, false, true);
        emit Deposit(commitment, expectedLeafIndex, block.timestamp);

        protocol.deposit(commitment, amount);

        assertEq(protocol.getUserDeposit(user1), amount);
        assertEq(protocol.getTotalDeposits(), amount);
        vm.stopPrank();
    }

    function testFailDepositInvalidAmount() public {
        vm.startPrank(user1);
        bytes32 commitment = keccak256("commitment1");
        uint256 amount = 0;

        token.approve(address(protocol), amount);
        protocol.deposit(commitment, amount);
        vm.stopPrank();
    }

    function testFailDoubleWithdraw() public {
        bytes32 nullifier = keccak256("nullifier1");
        bytes32[] memory merkleProof = new bytes32[](1);
        merkleProof[0] = bytes32(uint256(1));

        bytes32 newRoot = keccak256(abi.encodePacked(nullifier));
        protocol.updateMerkleRoot(newRoot);

        protocol.withdraw(nullifier, user2, 1 * 10 ** 18, merkleProof);
        protocol.withdraw(nullifier, user2, 1 * 10 ** 18, merkleProof);
    }

    function testEmergencyWithdraw() public {
        vm.startPrank(user1);
        bytes32 commitment = keccak256("commitment1");
        uint256 amount = 1 * 10 ** 18;
        token.approve(address(protocol), amount);
        protocol.deposit(commitment, amount);
        vm.stopPrank();

        uint256 initialBalance = token.balanceOf(owner);
        protocol.emergencyWithdraw();

        assertEq(token.balanceOf(address(protocol)), 0);
        assertEq(token.balanceOf(owner), initialBalance + amount);
    }

    function testFailEmergencyWithdrawNonOwner() public {
        vm.prank(user1);
        protocol.emergencyWithdraw();
    }

    function testVerifyZKProof() public {
        uint256[8] memory proof;
        uint256[2] memory input;

        proof[0] = 1;
        input[0] = 1;

        bool result = protocol.verifyZKProof(proof, input);
        assertTrue(result);
    }

    function testUpdateMerkleRoot() public {
        bytes32 newRoot = keccak256("newRoot");

        vm.expectEmit(true, false, false, true);
        emit NewMerkleRoot(1, newRoot);

        protocol.updateMerkleRoot(newRoot);

        assertEq(protocol.merkleRoots(1), newRoot);
        assertEq(protocol.currentRootIndex(), 1);
    }

    function testFailUpdateMerkleRootNonOwner() public {
        vm.prank(user1);
        protocol.updateMerkleRoot(keccak256("newRoot"));
    }

    function testGetUserDeposit() public {
        vm.startPrank(user1);
        bytes32 commitment = keccak256("commitment1");
        uint256 amount = 1 * 10 ** 18;

        token.approve(address(protocol), amount);
        protocol.deposit(commitment, amount);

        assertEq(protocol.getUserDeposit(user1), amount);
        vm.stopPrank();
    }

    function testGetTotalDeposits() public {
        vm.startPrank(user1);
        bytes32 commitment = keccak256("commitment1");
        uint256 amount = 1 * 10 ** 18;

        token.approve(address(protocol), amount);
        protocol.deposit(commitment, amount);

        assertEq(protocol.getTotalDeposits(), amount);
        vm.stopPrank();
    }

    function testFailDepositZeroCommitment() public {
        vm.startPrank(user1);
        bytes32 commitment = bytes32(0);
        uint256 amount = 1 * 10 ** 18;

        token.approve(address(protocol), amount);
        protocol.deposit(commitment, amount);
        vm.stopPrank();
    }
}
