// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165Upgradeable} from "openzeppelin-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IEIP2981} from "src/royalties/IEIP2981.sol";

/// @title EIP2981TLUpgradeable.sol
/// @notice Abstract contract to define a default royalty spec
///         while allowing for specific token overrides
/// @dev Follows EIP-2981 (https://eips.ethereum.org/EIPS/eip-2981)
/// @author transientlabs.xyz
/// @custom:version 3.0.0
abstract contract EIP2981TLUpgradeable is IEIP2981, ERC165Upgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                    Types
    //////////////////////////////////////////////////////////////////////////*/

    struct RoyaltySpec {
        address recipient;
        uint256 percentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    Storage
    //////////////////////////////////////////////////////////////////////////*/

    /// @custom:storage-location erc7201:transientlabs.storage.EIP2981TLStorage
    struct EIP2981TLStorage {
        address defaultRecipient;
        uint256 defaultPercentage;
        mapping(uint256 => RoyaltySpec) tokenOverrides;
    }

    // keccak256(abi.encode(uint256(keccak256("transientlabs.storage.EIP2981TLStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EIP2981TLStorageLocation =
        0xe9db8e9b56f2e28e12956850f386d9a4c1e886a4f584b61a10a9d0cacee70700;

    function _getEIP2981TLStorage() private pure returns (EIP2981TLStorage storage $) {
        assembly {
            $.slot := EIP2981TLStorageLocation
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Constants
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant BASIS = 10_000;

    /*//////////////////////////////////////////////////////////////////////////
                                    Errors
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev error if the recipient is set to address(0)
    error ZeroAddressError();

    /// @dev error if the royalty percentage is greater than to 100%
    error MaxRoyaltyError();

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to initialize the contract
    /// @param defaultRecipient The default royalty payout address
    /// @param defaultPercentage The deafult royalty percentage, out of 10,000
    function __EIP2981TL_init(address defaultRecipient, uint256 defaultPercentage) internal onlyInitializing {
        __EIP2981TL_init_unchained(defaultRecipient, defaultPercentage);
    }

    /// @notice Unchained function to initialize the contract
    /// @param defaultRecipient The default royalty payout address
    /// @param defaultPercentage The deafult royalty percentage, out of 10,000
    function __EIP2981TL_init_unchained(address defaultRecipient, uint256 defaultPercentage)
        internal
        onlyInitializing
    {
        _setDefaultRoyaltyInfo(defaultRecipient, defaultPercentage);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Changing Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to set default royalty info
    /// @param newRecipient The new default royalty payout address
    /// @param newPercentage The new default royalty percentage, out of 10,000
    function _setDefaultRoyaltyInfo(address newRecipient, uint256 newPercentage) internal {
        EIP2981TLStorage storage $ = _getEIP2981TLStorage();
        if (newRecipient == address(0)) revert ZeroAddressError();
        if (newPercentage > 10_000) revert MaxRoyaltyError();
        $.defaultRecipient = newRecipient;
        $.defaultPercentage = newPercentage;
    }

    /// @notice Function to override royalty spec on a specific token
    /// @param tokenId The token id to override royalty for
    /// @param newRecipient The new royalty payout address
    /// @param newPercentage The new royalty percentage, out of 10,000
    function _overrideTokenRoyaltyInfo(uint256 tokenId, address newRecipient, uint256 newPercentage) internal {
        EIP2981TLStorage storage $ = _getEIP2981TLStorage();
        if (newRecipient == address(0)) revert ZeroAddressError();
        if (newPercentage > 10_000) revert MaxRoyaltyError();
        $.tokenOverrides[tokenId].recipient = newRecipient;
        $.tokenOverrides[tokenId].percentage = newPercentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Royalty Info
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEIP2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        EIP2981TLStorage storage $ = _getEIP2981TLStorage();
        address recipient = $.defaultRecipient;
        uint256 percentage = $.defaultPercentage;
        if ($.tokenOverrides[tokenId].recipient != address(0)) {
            recipient = $.tokenOverrides[tokenId].recipient;
            percentage = $.tokenOverrides[tokenId].percentage;
        }
        return (recipient, salePrice * percentage / BASIS);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ERC-165 Override
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || ERC165Upgradeable.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            External View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Query the default royalty receiver and percentage.
    /// @return Tuple containing the default royalty recipient and percentage out of 10_000
    function getDefaultRoyaltyRecipientAndPercentage() external view returns (address, uint256) {
        EIP2981TLStorage storage $ = _getEIP2981TLStorage();
        return ($.defaultRecipient, $.defaultPercentage);
    }
}
