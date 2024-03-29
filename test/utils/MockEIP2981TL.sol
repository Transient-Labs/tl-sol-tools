// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {EIP2981TL} from "src/royalties/EIP2981TL.sol";

/// @dev this contract does not have proper access control but is only for testing

contract MockEIP2981TL is EIP2981TL {
    constructor(address recipient, uint256 percentage) EIP2981TL(recipient, percentage) {}

    /// @dev function to set new default royalties
    function setDefaultRoyalty(address recipient, uint256 percentage) external {
        _setDefaultRoyaltyInfo(recipient, percentage);
    }

    /// @dev function to set token specific royalties
    function setTokenRoyalty(uint256 tokenId, address recipient, uint256 percentage) external {
        _overrideTokenRoyaltyInfo(tokenId, recipient, percentage);
    }
}
