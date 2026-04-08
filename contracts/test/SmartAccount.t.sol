// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/SmartAccount.sol";
import "../src/SmartAccountFactory.sol";
import "../src/TokenPaymaster.sol";
import "./MockERC20.sol";
import "account-abstraction/contracts/core/EntryPoint.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SmartAccountTest is Test {
    using MessageHashUtils for bytes32;

    EntryPoint public entryPoint;
    SmartAccountFactory public factory;
    SmartAccount public account;
    TokenPaymaster public paymaster;
    MockERC20 public token;

    address owner = address(0xABCD);
    uint256 ownerKey = 0xABCD1234;
    address aiGuardian = address(0x1234);
    uint256 aiKey = 0x1234ABCD;

    function setUp() public {
        owner = vm.addr(ownerKey);
        aiGuardian = vm.addr(aiKey);

        entryPoint = new EntryPoint();
        factory = new SmartAccountFactory(entryPoint);
        account = factory.createAccount(owner, 0);
        
        token = new MockERC20("Mock USDC", "USDC");
        paymaster = new TokenPaymaster(entryPoint, address(this), token);

        // Stake and deposit for Paymaster
        vm.deal(address(this), 10 ether);
        paymaster.deposit{value: 2 ether}();
        paymaster.addStake{value: 1 ether}(1 days);

        vm.deal(address(account), 10 ether);
        token.mint(address(account), 1000 ether);
        vm.prank(address(account));
        token.approve(address(paymaster), type(uint256).max);
    }

    function testInitialize() public {
        assertEq(account.owner(), owner);
        assertEq(account.aiGuardian(), address(0)); // Factory initializes with zero address
    }

    function testSetAIGuardian() public {
        vm.prank(owner);
        account.setAIGuardian(aiGuardian);
        assertEq(account.aiGuardian(), aiGuardian);
    }

    function testExecute() public {
        address recipient = address(0xbeef);
        uint256 amount = 1 ether;

        vm.prank(address(entryPoint));
        account.execute(recipient, amount, "");

        assertEq(recipient.balance, amount);
    }

    function testValidateUserOpSingleSignature() public {
        PackedUserOperation memory userOp;
        userOp.sender = address(account);
        userOp.nonce = account.getNonce();
        
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes32 ethSignedHash = userOpHash.toEthSignedMessageHash();
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethSignedHash);
        userOp.signature = abi.encodePacked(r, s, v);

        vm.prank(address(entryPoint));
        uint256 validationData = account.validateUserOp(userOp, userOpHash, 0);
        
        assertEq(validationData, 0); // SIG_VALIDATION_SUCCESS
    }

    function testValidateUserOpDualSignature() public {
        // Set AI Guardian first
        vm.prank(owner);
        account.setAIGuardian(aiGuardian);

        PackedUserOperation memory userOp;
        userOp.sender = address(account);
        userOp.nonce = account.getNonce();
        
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes32 ethSignedHash = userOpHash.toEthSignedMessageHash();
        
        (uint8 vO, bytes32 rO, bytes32 sO) = vm.sign(ownerKey, ethSignedHash);
        bytes memory ownerSig = abi.encodePacked(rO, sO, vO);

        (uint8 vA, bytes32 rA, bytes32 sA) = vm.sign(aiKey, ethSignedHash);
        bytes memory aiSig = abi.encodePacked(rA, sA, vA);

        userOp.signature = abi.encodePacked(ownerSig, aiSig);

        vm.prank(address(entryPoint));
        uint256 validationData = account.validateUserOp(userOp, userOpHash, 0);
        
        assertEq(validationData, 0); // SIG_VALIDATION_SUCCESS
    }

    function testValidateUserOpFailure() public {
        PackedUserOperation memory userOp;
        userOp.sender = address(account);
        userOp.nonce = account.getNonce();
        
        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes32 ethSignedHash = userOpHash.toEthSignedMessageHash();
        
        // Sign with a wrong key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBAAD, ethSignedHash);
        userOp.signature = abi.encodePacked(r, s, v);

        vm.prank(address(entryPoint));
        uint256 validationData = account.validateUserOp(userOp, userOpHash, 0);
        
        assertEq(validationData, 1); // SIG_VALIDATION_FAILED
    }

    function testPaymasterSponsorship() public {
        PackedUserOperation memory userOp;
        userOp.sender = address(account);
        userOp.nonce = account.getNonce();
        userOp.callData = abi.encodeWithSelector(SmartAccount.execute.selector, address(0xbeef), 0.1 ether, "");
        
        // Pack gas limits: verificationGasLimit (128) || callGasLimit (128)
        userOp.accountGasLimits = bytes32((uint256(100000) << 128) | uint256(100000));
        userOp.preVerificationGas = 50000;
        // Pack gas fees: maxPriorityFeePerGas (128) || maxFeePerGas (128)
        userOp.gasFees = bytes32((uint256(1 gwei) << 128) | uint256(1 gwei));
        
        // Add paymaster data to userOp (v0.7 format: [paymaster(20)][verificationGas(16)][postOpGas(16)][paymasterData(bytes)])
        userOp.paymasterAndData = abi.encodePacked(
            address(paymaster),
            uint128(100000), // paymasterVerificationGas (16 bytes)
            uint128(100000), // paymasterPostOpGas (16 bytes)
            bytes("") // paymasterData
        );

        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
        bytes32 ethSignedHash = userOpHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethSignedHash);
        userOp.signature = abi.encodePacked(r, s, v);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        uint256 initialBalance = token.balanceOf(address(account));
        address beneficiary = address(0xdeadbeef);
        vm.prank(beneficiary, beneficiary);
        entryPoint.handleOps(ops, payable(beneficiary));
        uint256 finalBalance = token.balanceOf(address(account));

        assertTrue(finalBalance < initialBalance, "Tokens should have been deducted");
    }
}
