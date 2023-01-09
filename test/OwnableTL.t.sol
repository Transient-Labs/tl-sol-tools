// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { MockOwnableTL } from "./mocks/MockOwnableTL.sol";
import { ZeroAddressError, MaxRoyaltyError } from "../src/royalties/EIP2981TL.sol";

contract TestOwnableTL is Test {

    address public constant account = address(1);
    MockOwnableTL public mockContract;

    function setUp() public {
        mockContract = new MockOwnableTL();
    }

    ///////////////////// GENERAL TESTS /////////////////////
    function test_init() public {
        assertEq(mockContract.owner(), address(this));
        assertEq(mockContract.number(), 1);
    }

    function test_supportsInterface(address recipient, uint16 percentage) public {
        assertTrue(mockContract.supportsInterface(0x01ffc9a7)); // ERC165 interface id
        assertTrue(mockContract.supportsInterface(0x2a55205a)); // EIP173 interface id
    }
}