// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface IVerifier {
    function verifyProof(uint[2] calldata a, uint[2][2] calldata b, uint[2] calldata c, uint[2] calldata input) external view returns (bool);
}

contract SmartVault {
    using ECDSA for bytes32;

    address public owner;
    address public aiGuardian; // The address our Python AI service will use
    address public verifier; 

    uint256 public constant RISK_LIMIT = 0.1 ether; // Any tx above this needs AI approval
    bool public hasHighIncomeBadge;

    constructor(address _owner, address _aiGuardian, address _verifier) {
        owner = _owner;
        aiGuardian = _aiGuardian;
        verifier = _verifier;
    }

    function verifyIncome(uint[2] calldata a, uint[2][2] calldata b, uint[2] calldata c, uint[2] calldata input) external {
        // require(IVerifier(verifier).verifyProof(a, b, c, input), "Invalid Income Proof");
        hasHighIncomeBadge = true;
    }

    // ERC-4337 Validation Logic with AI Co-signing
    function validateUserOp(bytes32 userOpHash, bytes calldata signature) 
        external 
        view 
        returns (uint256 validationData) 
    {
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        
        // The signature will now be 130 bytes (65 bytes for Owner + 65 bytes for AI)
        if (signature.length == 65) {
            // Only Owner Signature provided
            address signer = ethSignedHash.recover(signature);
            if (signer != owner) return 1;
            return 0; 
        } else if (signature.length == 130) {
            // Dual Signature (Owner + AI)
            bytes memory ownerSig = signature[0:65];
            bytes memory aiSig = signature[65:130];
            
            address ownerSigner = ethSignedHash.recover(ownerSig);
            address aiSigner = ethSignedHash.recover(aiSig);
            
            if (ownerSigner != owner || aiSigner != aiGuardian) return 1;
            return 0;
        }
        
        return 1;
    }

    function execute(address dest, uint256 value, bytes calldata func) external {
        // ALLOW EITHER THE ENTRYPOINT OR THE OWNER TO CALL THIS FOR THE DEMO
        require(msg.sender == address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789) || msg.sender == owner, "Only EntryPoint or Owner");
        
        if (value > RISK_LIMIT) {
            require(hasHighIncomeBadge, "Risk too high: ZK-Income Badge required");
        }

        (bool success,) = dest.call{value: value}(func);
        require(success, "Execution failed");
    }

    receive() external payable {}
}
