// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/SmartVault.sol";
import "../src/ZKIdentityManager.sol";
import "./MockVerifier.sol";

contract SentinelTest is Test {
    SmartVault public vault;
    ZKIdentityManager public identityManager;
    MockVerifier public verifier;
    
    address owner = address(0xABCD);
    address aiGuardian = address(0x1234);
    address attacker = address(0xBEEF);

    function setUp() public {
        verifier = new MockVerifier();
        identityManager = new ZKIdentityManager(address(verifier), address(this));
        vault = new SmartVault(owner, aiGuardian, address(identityManager));
        vm.deal(address(vault), 10 ether);
    }

    function testAIGuardianCanPause() public {
        vm.prank(aiGuardian);
        vault.pause();
        assertTrue(vault.paused());
    }

    function testNonGuardianCannotPause() public {
        vm.prank(attacker);
        vm.expectRevert("Only AI Guardian");
        vault.pause();
    }

    function testWithdrawalsBlockedWhenPaused() public {
        vm.prank(aiGuardian);
        vault.pause();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        vault.execute(address(0xbeef), 0.1 ether, "");
    }

    function testOwnerCanUnpause() public {
        vm.prank(aiGuardian);
        vault.pause();

        vm.prank(owner);
        vault.unpause();
        assertFalse(vault.paused());
    }
}
