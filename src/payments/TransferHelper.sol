// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IWETH, IERC20} from "src/payments/IWETH.sol";

/// @title Transfer Helper
/// @notice Abstract contract that has helper function for sending ETH and ERC20's safely
/// @author transientlabs.xyz
/// @custom:version 3.0.0
abstract contract TransferHelper {
    /*//////////////////////////////////////////////////////////////////////////
                                    Types
    //////////////////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH;

    /*//////////////////////////////////////////////////////////////////////////
                                    Errors
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev ETH transfer failed
    error ETHTransferFailed();

    /// @dev Transferred too few ERC-20 tokens
    error InsufficentERC20Transfer();

    /*//////////////////////////////////////////////////////////////////////////
                                   ETH Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to force transfer ETH, defaulting to forwarding 100k gas
    /// @dev On failure to send the ETH, the ETH is converted to WETH and sent
    /// @dev Care should be taken to always pass the proper WETH address that adheres to IWETH
    /// @param recipient The recipient of the ETH
    /// @param amount The amount of ETH to send
    /// @param weth The WETH token address
    function _safeTransferETH(address recipient, uint256 amount, address weth) internal {
        _safeTransferETH(recipient, amount, weth, 1e5);
    }

    /// @notice Function to force transfer ETH, with a gas limit
    /// @dev On failure to send the ETH, the ETH is converted to WETH and sent
    /// @dev Care should be taken to always pass the proper WETH address that adheres to IWETH
    /// @dev If the `amount` is zero, the function returns in order to save gas
    /// @param recipient The recipient of the ETH
    /// @param amount The amount of ETH to send
    /// @param weth The WETH token address
    /// @param gasLimit The gas to forward
    function _safeTransferETH(address recipient, uint256 amount, address weth, uint256 gasLimit) internal {
        if (amount == 0) return;
        (bool success,) = recipient.call{value: amount, gas: gasLimit}("");
        if (!success) {
            IWETH token = IWETH(weth);
            token.deposit{value: amount}();
            token.safeTransfer(recipient, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  ERC-20 Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to safely transfer ERC-20 tokens from the contract, without checking for token tax
    /// @dev Does not check if the sender has enough balance as that is handled by the token contract
    /// @dev Does not check for token tax as that could lock up funds in the contract
    /// @dev Reverts on failure to transfer
    /// @dev If the `amount` is zero, the function returns in order to save gas
    /// @param recipient The recipient of the ERC-20 token
    /// @param currency The address of the ERC-20 token
    /// @param amount The amount of ERC-20 to send
    function _safeTransferERC20(address recipient, address currency, uint256 amount) internal {
        if (amount == 0) return;
        IERC20(currency).safeTransfer(recipient, amount);
    }

    /// @notice Function to safely transfer ERC-20 tokens from another address to a recipient
    /// @dev Does not check if the sender has enough balance or allowance for this contract as that is handled by the token contract
    /// @dev Reverts on failure to transfer
    /// @dev Reverts if there is a token tax taken out
    /// @dev Returns and doesn't do anything if the sender and recipient are the same address
    /// @dev If the `amount` is zero, the function returns in order to save gas
    /// @param sender The sender of the tokens
    /// @param recipient The recipient of the ERC-20 token
    /// @param currency The address of the ERC-20 token
    /// @param amount The amount of ERC-20 to send
    function _safeTransferFromERC20(address sender, address recipient, address currency, uint256 amount) internal {
        if (amount == 0) return;
        if (sender == recipient) return;
        IERC20 token = IERC20(currency);
        uint256 intialBalance = token.balanceOf(recipient);
        token.safeTransferFrom(sender, recipient, amount);
        uint256 finalBalance = token.balanceOf(recipient);
        if (finalBalance - intialBalance < amount) revert InsufficentERC20Transfer();
    }
}
