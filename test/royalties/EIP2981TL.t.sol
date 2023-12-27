// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MockEIP2981TL} from "test/utils/MockEIP2981TL.sol";
import {EIP2981TL} from "src/royalties/EIP2981TL.sol";

contract TestEIP2981TL is Test {
    MockEIP2981TL public mockContract;

    function test_DefaultRoyaltyInfo(uint256 tokenId, address recipient, uint16 percentage, uint256 saleAmount)
        public
    {
        if (recipient == address(0)) {
            vm.expectRevert(EIP2981TL.ZeroAddressError.selector);
        } else if (percentage > 10_000) {
            vm.expectRevert(EIP2981TL.MaxRoyaltyError.selector);
        } else {
            vm.expectEmit(true, true, true, true);
            emit EIP2981TL.DefaultRoyaltyUpdate(address(this), recipient, percentage);
        }
        mockContract = new MockEIP2981TL(recipient, uint256(percentage));
        if (recipient != address(0) && percentage <= 10_000) {
            if (saleAmount > 3_000_000 ether) {
                saleAmount = saleAmount % 3_000_000 ether;
            }
            uint256 expectedAmount = saleAmount * percentage / 10_000;
            (address returnedRecipient, uint256 amount) = mockContract.royaltyInfo(tokenId, saleAmount);
            assertEq(recipient, returnedRecipient);
            assertEq(amount, expectedAmount);
        }
    }

    function test_ERC165Support(address recipient, uint16 percentage) public {
        if (recipient != address(0) && percentage <= 10_000) {
            mockContract = new MockEIP2981TL(recipient, uint256(percentage));
            assertTrue(mockContract.supportsInterface(0x01ffc9a7)); // ERC165 interface id
            assertTrue(mockContract.supportsInterface(0x2a55205a)); // EIP2981 interface id
        }
    }

    function test_OverrideDefaultRoyaltyInfo(uint256 tokenId, address recipient, uint16 percentage, uint256 saleAmount)
        public
    {
        address defaultRecipient = makeAddr("account");
        mockContract = new MockEIP2981TL(defaultRecipient, 10_000);
        if (recipient == address(0)) {
            vm.expectRevert(EIP2981TL.ZeroAddressError.selector);
        } else if (percentage > 10_000) {
            vm.expectRevert(EIP2981TL.MaxRoyaltyError.selector);
        } else {
            vm.expectEmit(true, true, true, true);
            emit EIP2981TL.DefaultRoyaltyUpdate(address(this), recipient, percentage);
        }
        mockContract.setDefaultRoyalty(recipient, uint256(percentage));
        if (recipient != address(0) && percentage <= 10_000) {
            if (saleAmount > 3_000_000 ether) {
                saleAmount = saleAmount % 3_000_000 ether;
            }
            uint256 expectedAmount = saleAmount * percentage / 10_000;
            (address returnedRecipient, uint256 amount) = mockContract.royaltyInfo(tokenId, saleAmount);
            assertEq(recipient, returnedRecipient);
            assertEq(amount, expectedAmount);
        }
    }

    function test_OverrideTokenRoyaltyInfo(uint256 tokenId, address recipient, uint16 percentage, uint256 saleAmount)
        public
    {
        address defaultRecipient = makeAddr("account");
        mockContract = new MockEIP2981TL(defaultRecipient, 10_000);
        if (recipient == address(0)) {
            vm.expectRevert(EIP2981TL.ZeroAddressError.selector);
        } else if (percentage > 10_000) {
            vm.expectRevert(EIP2981TL.MaxRoyaltyError.selector);
        } else {
            vm.expectEmit(true, true, true, true);
            emit EIP2981TL.TokenRoyaltyOverride(address(this), tokenId, recipient, percentage);
        }
        mockContract.setTokenRoyalty(tokenId, recipient, uint256(percentage));
        if (recipient != address(0) && percentage <= 10_000) {
            if (saleAmount > 3_000_000 ether) {
                saleAmount = saleAmount % 3_000_000 ether;
            }
            uint256 expectedAmount = saleAmount * percentage / 10_000;
            (address returnedRecipient, uint256 amount) = mockContract.royaltyInfo(tokenId, saleAmount);
            assertEq(recipient, returnedRecipient);
            assertEq(amount, expectedAmount);
        }
    }
}
