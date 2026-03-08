// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SmartVault.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        new SmartVault(
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            0x4e507a4575d71c1E7EAAfaB9F6Ff0fde730DeD29,
            0x5FbDB2315678afecb367f032d93F642f64180aa3
        );
        vm.stopBroadcast();
    }
}
