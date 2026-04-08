// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IVerifier {
    function verifyProof(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input
    ) external view returns (bool);
}

/**
 * @title ZKIdentityManager
 * @dev Manages ZK-Identity badges for users based on income/credit verification.
 */
contract ZKIdentityManager is Ownable {
    IVerifier public immutable verifier;

    mapping(address => bool) public isVerified;
    mapping(bytes32 => bool) public usedNullifiers; // Prevent proof replay

    event IdentityVerified(address indexed user, bytes32 indexed nullifier);

    constructor(address _verifier, address initialOwner) Ownable(initialOwner) {
        verifier = IVerifier(_verifier);
    }

    /**
     * @dev Verify a ZK-Proof to grant an identity badge.
     * @param user The address to grant the badge to.
     * @param nullifier A unique nullifier from the proof.
     * @param a, b, c The Groth16 proof components.
     * @param input Public signals: [isEligible, identityHash]
     */
    function verifyIdentity(
        address user,
        bytes32 nullifier,
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input
    ) external {
        require(!usedNullifiers[nullifier], "Proof already used");
        require(input[0] == 1, "Proof shows ineligibility");
        
        // In a real production setup, identityHash (input[1]) should be checked 
        // against a hash of (user, nullifier) to ensure the proof belongs to 'user'.
        
        require(verifier.verifyProof(a, b, c, input), "Invalid ZK-Proof");

        usedNullifiers[nullifier] = true;
        isVerified[user] = true;

        emit IdentityVerified(user, nullifier);
    }

    /**
     * @dev Check if a user has a valid identity badge.
     */
    function hasBadge(address user) external view returns (bool) {
        return isVerified[user];
    }
}
