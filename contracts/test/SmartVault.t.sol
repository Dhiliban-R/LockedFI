// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SmartVault.sol";
import "../src/Verifier.sol";

contract SmartVaultTest is Test {
    SmartVault public vault;
    Groth16Verifier public verifier;
    
    address owner = address(0xABCD);
    address aiGuardian = address(0x1234);
    address entryPoint = address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    function setUp() public {
        verifier = new Groth16Verifier();
        vault = new SmartVault(owner, aiGuardian, address(verifier));
        vm.deal(address(vault), 1 ether);
    }

    function testSmallWithdrawal() public {
        vm.prank(entryPoint);
        vault.execute(address(0xbeef), 0.05 ether, "");
        assertEq(address(0xbeef).balance, 0.05 ether);
    }

    function testLargeWithdrawalFailsWithoutBadge() public {
        vm.prank(entryPoint);
        vm.expectRevert("Risk too high: ZK-Income Badge required");
        vault.execute(address(0xbeef), 0.2 ether, "");
    }

    // FIX: Expect the security library to REVERT on a fake 65-byte signature
    function testValidationFailsOnInvalidSignature() public {
        bytes32 mockHash = keccak256("tx_data");
        bytes memory signature = new bytes(65); 
        
        // We expect the ECDSA library to catch the fake signature and revert
        vm.expectRevert(); 
        vault.validateUserOp(mockHash, signature);
    }
}
