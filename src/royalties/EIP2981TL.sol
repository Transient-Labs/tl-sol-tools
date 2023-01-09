// SPDX-License-Identifier: Apache-2.0

/// @title EIP2981TL.sol
/// @notice contract to define a default royalty spec 
///         while allowing for specific token overrides
/// @dev contract is meant to be deployed in a minimal proxy pattern 
///      so using upgradeable intializers instead of constructors
/// @author transientlabs.xyz

/*
    ____        _ __    __   ____  _ ________                     __ 
   / __ )__  __(_) /___/ /  / __ \(_) __/ __/__  ________  ____  / /_
  / __  / / / / / / __  /  / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ __/
 / /_/ / /_/ / / / /_/ /  / /_/ / / __/ __/  __/ /  /  __/ / / / /__ 
/_____/\__,_/_/_/\__,_/  /_____/_/_/ /_/  \___/_/   \___/_/ /_/\__(_)

*/

pragma solidity 0.8.17;

///////////////////// IMPORTS /////////////////////

import { ERC165 } from "openzeppelin/utils/introspection/ERC165.sol";
import { IEIP2981 } from "./IEIP2981.sol";

///////////////////// CUSTOM ERRORS /////////////////////

/// @dev error if the recipient is set to address(0)
error ZeroAddressError();

/// @dev error if the royalty percentage is greater than to 100%
error MaxRoyaltyError();

///////////////////// EIP2981TL CONTRACT /////////////////////

abstract contract EIP2981TL is IEIP2981, ERC165 {

    ///////////////////// ROYALTY SPEC /////////////////////

    struct RoyaltySpec {
        address recipient;
        uint256 percentage;
    }

    ///////////////////// STORAGE VARIABLES /////////////////////

    address private _defaultRecipient;
    uint256 private _defaultPercentage;
    mapping(uint256 => RoyaltySpec) private _tokenOverrides;

    ///////////////////// CONSTRUCTOR /////////////////////

    constructor(address defaultRecipient, uint256 defaultPercentage) {
        _setDefaultRoyaltyInfo(defaultRecipient, defaultPercentage);
    }

    ///////////////////// ROYALTY FUNCTIONS /////////////////////

    /// @notice function to set default royalty info
    function _setDefaultRoyaltyInfo(address newRecipient, uint256 newPercentage) internal {
        if (newRecipient == address(0)) { revert ZeroAddressError(); }
        if (newPercentage > 10_000) { revert MaxRoyaltyError(); }
        _defaultRecipient = newRecipient;
        _defaultPercentage = newPercentage;
    }

    /// @notice function to override royalty spec on a specific token
    function _overrideTokenRoyaltyInfo(uint256 tokenId, address newRecipient, uint256 newPercentage) internal {
        if (newRecipient == address(0)) { revert ZeroAddressError(); }
        if (newPercentage > 10_000) { revert MaxRoyaltyError(); }
        _tokenOverrides[tokenId].recipient = newRecipient;
        _tokenOverrides[tokenId].percentage = newPercentage;
    }

    /// @notice see { IEIP291.royaltyInfo }
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        address recipient = _defaultRecipient;
        uint256 percentage = _defaultPercentage;
        if (_tokenOverrides[tokenId].recipient != address(0)) {
            recipient = _tokenOverrides[tokenId].recipient;
            percentage = _tokenOverrides[tokenId].percentage;
        }
        return (recipient, salePrice / 10_000 * percentage); // divide first to avoid overflow
    }

    ///////////////////// ERC-165 OVERRIDE /////////////////////

    /// @notice see { ERC165Upgradeable.supportsInterface }
    /// @dev if using this contract with another contract that suppports ERC-165, will have to override in the inheriting contract
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IEIP2981).interfaceId || ERC165.supportsInterface(interfaceId);
    }

}