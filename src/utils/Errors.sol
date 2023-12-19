// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Errors.sol
/// @notice custom errors to use in contracts
/// @author transientlabs.xyz
/// @custom:version 3.0.0
contract Errors {

    /// @dev Does not have specified role
    error NotSpecifiedRole(bytes32 role);

    /// @dev Is not specified role or owner
    error NotRoleOrOwner(bytes32 role);

    /// @dev ETH transfer failed
    error ETHTransferFailed();

    /// @dev Transferred too few ERC-20 tokens
    error InsufficentERC20Transfer();

    /// @dev Sanctioned address by OFAC
    error SanctionedAddress();

    /// @dev error if the recipient is set to address(0)
    error ZeroAddressError();

    /// @dev error if the royalty percentage is greater than to 100%
    error MaxRoyaltyError();
}
