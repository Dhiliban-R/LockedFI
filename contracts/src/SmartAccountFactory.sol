// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./SmartAccount.sol";
import "account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title SmartAccountFactory
 * @dev A deterministic factory for creating SmartAccount instances.
 */
contract SmartAccountFactory {
    IEntryPoint public immutable entryPoint;

    constructor(IEntryPoint _entryPoint) {
        entryPoint = _entryPoint;
    }

    /**
     * @dev Create a new SmartAccount.
     * @param owner The initial owner of the account.
     * @param salt A unique salt for deterministic deployment.
     */
    function createAccount(address owner, uint256 salt) external returns (SmartAccount) {
        address addr = getAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return SmartAccount(payable(addr));
        }

        SmartAccount account = new SmartAccount{salt: bytes32(salt)}(entryPoint);
        account.initialize(owner, address(0)); // Start with no AI guardian initially
        return account;
    }

    /**
     * @dev Compute the deterministic address of a SmartAccount before deployment.
     */
    function getAddress(address owner, uint256 salt) public view returns (address) {
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(abi.encodePacked(type(SmartAccount).creationCode, abi.encode(entryPoint)))
        );
    }
}
