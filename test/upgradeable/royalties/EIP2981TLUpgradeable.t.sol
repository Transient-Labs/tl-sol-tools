// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MockEIP2981TLUpgradeable} from "test/utils/MockEIP2981TLUpgradeable.sol";
import {EIP2981TLUpgradeable} from "src/upgradeable/royalties/EIP2981TLUpgradeable.sol";

contract TestEIP2981TLUpgradeable is Test {
    MockEIP2981TLUpgradeable public mockContract;

    function test_DefaultRoyaltyInfo(uint256 tokenId, address recipient, uint16 percentage, uint256 saleAmount)
        public
    {
        mockContract = new MockEIP2981TLUpgradeable();
        if (recipient == address(0)) {
            vm.expectRevert(EIP2981TLUpgradeable.ZeroAddressError.selector);
        } else if (percentage > 10_000) {
            vm.expectRevert(EIP2981TLUpgradeable.MaxRoyaltyError.selector);
        } else {
            vm.expectEmit(true, true, true, true);
            emit EIP2981TLUpgradeable.DefaultRoyaltyUpdate(address(this), recipient, percentage);
        }
        mockContract.initialize(recipient, uint256(percentage));
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
            mockContract = new MockEIP2981TLUpgradeable();
            mockContract.initialize(recipient, uint256(percentage));
            assertTrue(mockContract.supportsInterface(0x01ffc9a7)); // ERC165 interface id
            assertTrue(mockContract.supportsInterface(0x2a55205a)); // EIP2981 interface id
        }
    }

    function test_OverrideDefaultRoyalty(uint256 tokenId, address recipient, uint16 percentage, uint256 saleAmount)
        public
    {
        address defaultRecipient = makeAddr("account");
        mockContract = new MockEIP2981TLUpgradeable();
        mockContract.initialize(defaultRecipient, 10_000);
        if (recipient == address(0)) {
            vm.expectRevert(EIP2981TLUpgradeable.ZeroAddressError.selector);
        } else if (percentage > 10_000) {
            vm.expectRevert(EIP2981TLUpgradeable.MaxRoyaltyError.selector);
        } else {
            vm.expectEmit(true, true, true, true);
            emit EIP2981TLUpgradeable.DefaultRoyaltyUpdate(address(this), recipient, percentage);
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
        mockContract = new MockEIP2981TLUpgradeable();
        mockContract.initialize(defaultRecipient, 10_000);
        if (recipient == address(0)) {
            vm.expectRevert(EIP2981TLUpgradeable.ZeroAddressError.selector);
        } else if (percentage > 10_000) {
            vm.expectRevert(EIP2981TLUpgradeable.MaxRoyaltyError.selector);
        } else {
            vm.expectEmit(true, true, true, true);
            emit EIP2981TLUpgradeable.TokenRoyaltyOverride(address(this), tokenId, recipient, percentage);
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
