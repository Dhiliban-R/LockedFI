pragma circom 2.0.0;

include "../../contracts/lib/circomlib/circuits/comparators.circom";
include "../../contracts/lib/circomlib/circuits/poseidon.circom";

/**
 * @title IncomeVerifier
 * @dev Verifies that a private income is greater than or equal to a public threshold.
 * Also includes a salt/nullifier to prevent replay attacks.
 */
template IncomeVerifier() {
    // Private Inputs
    signal input privateIncome;
    signal input salt;

    // Public Inputs
    signal input publicThreshold;
    signal input userAddress; // To link the proof to a specific address

    // Outputs
    signal output isEligible;
    signal output identityHash;

    // 1. Check if privateIncome >= publicThreshold
    component gte = GreaterEqThan(64); // Assuming income fits in 64 bits
    gte.in[0] <== privateIncome;
    gte.in[1] <== publicThreshold;
    
    isEligible <== gte.out;
    isEligible === 1; // The proof only verifies if the user is eligible

    // 2. Generate an identity hash to link the proof to the user and the salt
    component hasher = Poseidon(2);
    hasher.inputs[0] <== userAddress;
    hasher.inputs[1] <== salt;
    identityHash <== hasher.out;
}

component main { public [publicThreshold, userAddress] } = IncomeVerifier();
