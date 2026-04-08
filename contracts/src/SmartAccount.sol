// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "account-abstraction/contracts/core/BaseAccount.sol";
import "account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @title SmartAccount
 * @dev A production-ready, ERC-4337 v0.7 compliant smart account with AI-Guardian support.
 */
contract SmartAccount is BaseAccount {
    using ECDSA for bytes32;

    address public owner;
    address public aiGuardian;
    IEntryPoint private immutable _entryPoint;

    event SmartAccountInitialized(IEntryPoint indexed entryPoint, address indexed owner);
    event AIGuardianUpdated(address indexed newGuardian);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(IEntryPoint entryPoint_) {
        _entryPoint = entryPoint_;
    }

    /**
     * @dev Initialize the account with an owner and optionally an AI Guardian.
     */
    function initialize(address initialOwner, address initialAIGuardian) external {
        require(owner == address(0), "Already initialized");
        owner = initialOwner;
        aiGuardian = initialAIGuardian;
        emit SmartAccountInitialized(_entryPoint, initialOwner);
        if (initialAIGuardian != address(0)) {
            emit AIGuardianUpdated(initialAIGuardian);
        }
    }

    /**
     * @dev Implementation of the base account entryPoint() getter.
     */
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * @dev execute a single call from the account.
     */
    function execute(address target, uint256 value, bytes calldata data) external virtual override {
        _requireForExecute();
        bool ok = Exec.call(target, value, data, gasleft());
        if (!ok) {
            Exec.revertWithReturnData();
        }
    }

    /**
     * @dev execute a batch of calls.
     */
    function executeBatch(Call[] calldata calls) external virtual override {
        _requireForExecute();

        uint256 callsLength = calls.length;
        for (uint256 i = 0; i < callsLength; i++) {
            Call calldata call = calls[i];
            bool ok = Exec.call(call.target, call.value, call.data, gasleft());
            if (!ok) {
                if (callsLength == 1) {
                    Exec.revertWithReturnData();
                } else {
                    revert ExecuteError(i, Exec.getReturnData(0));
                }
            }
        }
    }

    /**
     * @dev Set a new AI Guardian.
     */
    function setAIGuardian(address newGuardian) external onlyOwner {
        aiGuardian = newGuardian;
        emit AIGuardianUpdated(newGuardian);
    }

    /**
     * @dev Implementation of _validateSignature from BaseAccount.
     * Supports single owner signature (65 bytes) or dual signature (Owner + AI, 130 bytes).
     */
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        bytes calldata signature = userOp.signature;

        if (signature.length == 65) {
            // Single owner signature
            if (hash.recover(signature) != owner) {
                return 1; // SIG_VALIDATION_FAILED
            }
        } else if (signature.length == 130) {
            // Dual signature: [Owner Sig (65)][AI Sig (65)]
            bytes calldata ownerSig = signature[0:65];
            bytes calldata aiSig = signature[65:130];

            if (hash.recover(ownerSig) != owner) {
                return 1;
            }
            if (hash.recover(aiSig) != aiGuardian) {
                return 1;
            }
        } else {
            return 1;
        }

        return 0; // SIG_VALIDATION_SUCCESS
    }

    /**
     * @dev Required to allow the account to receive ETH.
     */
    receive() external payable {}
}
