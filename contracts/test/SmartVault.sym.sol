// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/SmartVault.sol";
import "../src/ZKIdentityManager.sol";
import "./MockVerifier.sol";

/**
 * @title SmartVaultSymbolicTest
 * @dev Symbolic properties for SmartVault formal verification.
 */
contract SmartVaultSymbolicTest is Test {
    SmartVault public vault;
    ZKIdentityManager public identityManager;
    MockVerifier public verifier;
    
    address owner = address(0xABCD);
    address aiGuardian = address(0x1234);
    address entryPoint = address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    function setUp() public {
        verifier = new MockVerifier();
        identityManager = new ZKIdentityManager(address(verifier), address(this));
        vault = new SmartVault(owner, aiGuardian, address(identityManager));
        
        uint256 initialFunds = 100 ether;
        vm.deal(address(this), initialFunds);
        vault.deposit{value: initialFunds}();
    }

    /**
     * @dev Property: Only the AI Guardian can pause the vault.
     */
    function test_only_guardian_can_pause(address caller) public {
        vm.assume(caller != aiGuardian);
        
        vm.prank(caller);
        vm.expectRevert("Only AI Guardian");
        vault.pause();
    }

    /**
     * @dev Property: Only the owner can unpause.
     */
    function test_only_owner_can_unpause(address caller) public {
        vm.prank(aiGuardian);
        vault.pause();
        
        vm.assume(caller != owner);
        
        vm.prank(caller);
        vm.expectRevert(); // OwnableUnauthorizedAccount or similar
        vault.unpause();
    }

    /**
     * @dev Property: Small withdrawals (< RISK_LIMIT) by owner always succeed when not paused.
     */
    function test_owner_can_execute_small(address target, uint256 amount) public {
        vm.assume(amount <= vault.RISK_LIMIT());
        vm.assume(amount <= address(vault).balance);
        vm.assume(target != address(vault));
        vm.assume(target.code.length == 0);
        
        vm.prank(owner);
        vault.execute(target, amount, "");
    }

    /**
     * @dev Property: Large withdrawals (> RISK_LIMIT) by owner fail without ZK-badge.
     */
    function test_large_withdrawal_fails_without_badge(address target, uint256 amount) public {
        vm.assume(amount > vault.RISK_LIMIT());
        vm.assume(amount <= address(vault).balance);
        vm.assume(!identityManager.hasBadge(owner));
        
        vm.prank(owner);
        vm.expectRevert("Risk too high: ZK-Income Badge required");
        vault.execute(target, amount, "");
    }

    /**
     * @dev Property: Any address other than owner or EntryPoint cannot execute.
     */
    function test_only_privileged_can_execute(address caller, address target, uint256 amount) public {
        vm.assume(caller != owner);
        vm.assume(caller != entryPoint);
        
        vm.prank(caller);
        vm.expectRevert("Only EntryPoint or Owner");
        vault.execute(target, amount, "");
    }
}
