// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/SmartVault.sol";

contract SmartVaultDeployTest is Test {
    function testDeploy() public {
        address owner = address(0xABCD);
        address aiGuardian = address(0x1234);
        address identityManager = address(0x5678);
        
        SmartVault vault = new SmartVault(owner, aiGuardian, identityManager);
        assertEq(vault.owner(), owner);
        assertEq(vault.aiGuardian(), aiGuardian);
        assertEq(vault.identityManager(), identityManager);
    }
}
