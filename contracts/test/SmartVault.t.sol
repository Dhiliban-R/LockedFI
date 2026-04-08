// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/SmartVault.sol";
import "../src/SmartVaultFactory.sol";
import "../src/ZKIdentityManager.sol";
import "./MockVerifier.sol";

contract SmartVaultTest is Test {
    SmartVault public vault;
    SmartVaultFactory public factory;
    ZKIdentityManager public identityManager;
    MockVerifier public verifier;
    
    address owner = address(0xABCD);
    address aiGuardian = address(0x1234);

    function setUp() public {
        verifier = new MockVerifier();
        identityManager = new ZKIdentityManager(address(verifier), address(this));
        factory = new SmartVaultFactory();
        
        vault = factory.createVault(owner, aiGuardian, address(identityManager), 0);
    }

    function testDeterministicDeployment() public {
        address expected = factory.getAddress(owner, aiGuardian, address(identityManager), 123);
        SmartVault vault2 = factory.createVault(owner, aiGuardian, address(identityManager), 123);
        assertEq(address(vault2), expected);
    }

    function testDepositAndSolvency() public {
        uint256 amount = 1 ether;
        vm.deal(address(this), amount);
        
        vault.deposit{value: amount}();
        assertEq(vault.totalAssets(), amount);
        assertEq(address(vault).balance, amount);
    }

    function testYieldHarvesting() public {
        uint256 amount = 100 ether;
        vm.deal(address(this), amount);
        vault.deposit{value: amount}();

        vm.prank(aiGuardian);
        vault.harvestYield();

        assertEq(vault.totalAssets(), 101 ether); // 1% yield
    }

    function testExecuteUpdatesSolvency() public {
        uint256 amount = 1 ether;
        vm.deal(address(this), amount);
        vault.deposit{value: amount}();

        vm.prank(owner);
        vault.execute(address(0xbeef), 0.1 ether, "");
        
        assertEq(vault.totalAssets(), 0.9 ether);
    }
}
