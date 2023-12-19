// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///
/// @dev Interface for the NFT Royalty Standard
///
interface IEIP2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param tokenId The NFT asset queried for royalty information
    /// @param salePrice The sale price of the NFT asset specified by tokenId
    /// @return receiver Address of who should be sent the royalty payment
    /// @return royaltyAmount The royalty payment amount for salePrice
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}
