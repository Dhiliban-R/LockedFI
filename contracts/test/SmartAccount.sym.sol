// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/SmartAccount.sol";
import "account-abstraction/contracts/core/EntryPoint.sol";

/**
 * @title SmartAccountSymbolicTest
 * @dev Symbolic properties for formal verification using Halmos or Kontrol.
 */
contract SmartAccountSymbolicTest is Test {
    SmartAccount public account;
    EntryPoint public entryPoint;
    
    address owner = address(0x123);
    address aiGuardian = address(0x456);

    function setUp() public {
        entryPoint = new EntryPoint();
        account = new SmartAccount(entryPoint);
        account.initialize(owner, aiGuardian);
    }

    /**
     * @dev Property: initialize can only be called once.
     */
    function test_initialize_once(address newOwner, address newGuardian) public {
        vm.expectRevert("Already initialized");
        account.initialize(newOwner, newGuardian);
    }

    /**
     * @dev Property: Only the owner can set a new AI Guardian.
     */
    function test_only_owner_can_set_guardian(address caller, address newGuardian) public {
        vm.assume(caller != owner);
        
        vm.prank(caller);
        vm.expectRevert("Only owner");
        account.setAIGuardian(newGuardian);
    }

    /**
     * @dev Property: setAIGuardian succeeds if caller is owner.
     */
    function test_owner_can_set_guardian(address newGuardian) public {
        vm.prank(owner);
        account.setAIGuardian(newGuardian);
        assertEq(account.aiGuardian(), newGuardian);
    }

    /**
     * @dev Property: execute only succeeds if caller is EntryPoint.
     */
    function test_only_entrypoint_can_execute(address caller, address target, uint256 value, bytes calldata data) public {
        vm.assume(caller != address(entryPoint));
        
        vm.prank(caller);
        vm.expectRevert(); // BaseAccount's NotFromEntryPoint error
        account.execute(target, value, data);
    }

    /**
     * @dev Property: entryPoint is immutable and correctly set.
     */
    function test_entrypoint_immutable() public view {
        assertEq(address(account.entryPoint()), address(entryPoint));
    }
}
