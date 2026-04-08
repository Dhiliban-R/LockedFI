// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./SmartVault.sol";

/**
 * @title SmartVaultFactory
 * @dev A deterministic factory for creating SmartVault instances.
 */
contract SmartVaultFactory {
    event VaultCreated(address indexed vault, address indexed owner, address aiGuardian);

    /**
     * @dev Create a new SmartVault.
     * @param owner The initial owner of the vault.
     * @param aiGuardian The address of the AI Sentinel.
     * @param identityManager The address of the ZK Identity Manager.
     * @param salt A unique salt for deterministic deployment.
     */
    function createVault(
        address owner,
        address aiGuardian,
        address identityManager,
        uint256 salt
    ) external returns (SmartVault) {
        address addr = getAddress(owner, aiGuardian, identityManager, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return SmartVault(payable(addr));
        }

        SmartVault vault = new SmartVault{salt: bytes32(salt)}(owner, aiGuardian, identityManager);
        emit VaultCreated(address(vault), owner, aiGuardian);
        return vault;
    }

    /**
     * @dev Compute the deterministic address of a SmartVault before deployment.
     */
    function getAddress(
        address owner,
        address aiGuardian,
        address identityManager,
        uint256 salt
    ) public view returns (address) {
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(
                abi.encodePacked(
                    type(SmartVault).creationCode,
                    abi.encode(owner, aiGuardian, identityManager)
                )
            )
        );
    }
}
