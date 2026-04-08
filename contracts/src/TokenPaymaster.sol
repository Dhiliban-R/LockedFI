// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "account-abstraction/contracts/core/BasePaymaster.sol";

/**
 * @title TokenPaymaster
 * @dev A paymaster that allows users to pay for gas with a specific ERC20 token.
 */
contract TokenPaymaster is BasePaymaster {
    IERC20 public immutable token;
    uint256 public constant TOKEN_TO_ETH_RATIO = 1; // 1:1 for simplicity in this demo

    error InsufficientTokenBalance(address user, uint256 required, uint256 actual);

    constructor(IEntryPoint _entryPoint, address _owner, IERC20 _token) BasePaymaster(_entryPoint, _owner) {
        token = _token;
    }

    /**
     * @dev Internal validation logic for the paymaster.
     */
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 maxCost
    ) internal virtual override returns (bytes memory context, uint256 validationData) {
        uint256 requiredTokens = maxCost * TOKEN_TO_ETH_RATIO;
        
        // In a real paymaster, we'd check if the user has enough tokens and has approved us.
        // For ERC-4337 v0.7, the paymaster often pulls tokens during the validation phase
        // or during the postOp phase.
        
        uint256 balance = token.balanceOf(userOp.sender);
        if (balance < requiredTokens) {
            revert InsufficientTokenBalance(userOp.sender, requiredTokens, balance);
        }

        // Context contains the user address to be used in postOp
        context = abi.encode(userOp.sender);
        validationData = 0; // SIG_VALIDATION_SUCCESS
    }

    /**
     * @dev Deduct tokens from the user after the transaction.
     */
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) internal virtual override {
        (mode, actualUserOpFeePerGas); // unused params
        
        address user = abi.decode(context, (address));
        uint256 tokenAmount = actualGasCost * TOKEN_TO_ETH_RATIO;
        
        // Pull tokens from user (requires approval)
        token.transferFrom(user, address(this), tokenAmount);
    }
}
