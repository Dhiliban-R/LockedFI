// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract MockVerifier {
    bool public alwaysValid = true;

    function setAlwaysValid(bool _valid) external {
        alwaysValid = _valid;
    }

    function verifyProof(
        uint[2] calldata,
        uint[2][2] calldata,
        uint[2] calldata,
        uint[2] calldata
    ) external view returns (bool) {
        return alwaysValid;
    }
}
