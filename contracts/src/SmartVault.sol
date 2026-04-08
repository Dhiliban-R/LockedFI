// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IZKIdentityManager {
    function hasBadge(address user) external view returns (bool);
    function verifyIdentity(
        address user,
        bytes32 nullifier,
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input
    ) external;
}

/**
 * @dev SmartVault manages assets and enforces ZK-Identity checks.
 */
contract SmartVault is Pausable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    address public aiGuardian; 
    address public identityManager; 

    uint256 public constant RISK_LIMIT = 0.1 ether; 
    uint256 public totalAssets; 

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, address indexed to, uint256 amount);
    event YieldGenerated(uint256 amount);
    event CrossChainTransferInitiated(uint32 indexed dstChainId, address indexed to, uint256 amount);

    constructor(address _owner, address _aiGuardian, address _identityManager) Ownable(_owner) {
        aiGuardian = _aiGuardian;
        identityManager = _identityManager;
    }

    /**
     * @dev Deposit ETH into the vault and earn yield.
     */
    function deposit() external payable whenNotPaused {
        totalAssets += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Simple yield logic: simulate yield accrual (for demo).
     */
    function harvestYield() external onlyGuardian nonReentrant {
        uint256 yield = totalAssets / 100; // 1% yield simulation
        totalAssets += yield;
        emit YieldGenerated(yield);
    }

    /**
     * @dev Initiate a cross-chain transfer (Bridge-Ready).
     * @param dstChainId The destination chain ID (LayerZero format).
     * @param to The recipient address on the destination chain.
     * @param amount The amount to transfer.
     */
    function initiateCrossChainTransfer(uint32 dstChainId, address to, uint256 amount) external onlyOwner whenNotPaused nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");

        // Safeguard totalAssets from underflow (Accounting correction)
        if (totalAssets < amount) {
            totalAssets = 0;
        } else {
            totalAssets -= amount;
        }
        
        // In production, this would call LayerZero Endpoint or CCIP Router
        // For this architecture, we emit an event for the bridge relayer
        emit CrossChainTransferInitiated(dstChainId, to, amount);
        
        // Burn or lock assets
        payable(address(0xdead)).transfer(amount); // Simulation: "Lock" by sending to dead address
    }

    modifier onlyGuardian() {
        require(msg.sender == aiGuardian, "Only AI Guardian");
        _;
    }

    function pause() external onlyGuardian {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setAIGuardian(address _newGuardian) external onlyOwner {
        aiGuardian = _newGuardian;
    }

    /**
     * @dev Check if the owner has a high income badge.
     */
    function hasHighIncomeBadge() external view returns (bool) {
        return IZKIdentityManager(identityManager).hasBadge(owner());
    }

    /**
     * @dev Verify a ZK-Proof to grant a high income badge.
     */
    function verifyIncome(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input
    ) external {
        // Use a deterministic nullifier for the demo based on owner address
        bytes32 nullifier = keccak256(abi.encodePacked(owner(), "income-nullifier"));
        IZKIdentityManager(identityManager).verifyIdentity(owner(), nullifier, a, b, c, input);
    }

    function execute(address dest, uint256 value, bytes calldata func) external whenNotPaused nonReentrant {
        // ALLOW EITHER THE ENTRYPOINT OR THE OWNER TO CALL THIS FOR THE DEMO
        require(msg.sender == address(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789) || msg.sender == owner(), "Only EntryPoint or Owner");

        if (value > RISK_LIMIT) {
            require(IZKIdentityManager(identityManager).hasBadge(owner()), "Risk too high: ZK-Income Badge required");
        }

        require(address(this).balance >= value, "Insufficient vault balance");
        
        // Safeguard totalAssets from underflow (Accounting correction)
        if (totalAssets < value) {
            totalAssets = 0;
        } else {
            totalAssets -= value;
        }

        // Check if destination is a contract or EOA
        uint256 size;
        assembly {
            size := extcodesize(dest)
        }

        if (size > 0) {
            // Dest is a contract, use call
            (bool success,) = dest.call{value: value}(func);
            require(success, "Contract execution failed");
        } else {
            // Dest is an EOA, use transfer (standard ETH transfer)
            if (value > 0) {
                (bool success,) = dest.call{value: value}("");
                require(success, "ETH transfer failed");
            }
            // If func data is provided but dest is EOA, we can't execute it
            // This is expected behavior for simple ETH transfers
        }

        emit Withdrawal(msg.sender, dest, value);
    }

    receive() external payable {
        totalAssets += msg.value;
    }
}
