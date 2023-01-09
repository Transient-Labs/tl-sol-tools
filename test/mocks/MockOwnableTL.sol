// SPDX-License-Identifier: Apache-2.0

/// @dev this contract does not have proper access control but is only for testing

pragma solidity 0.8.17;

import { OwnableTL } from "../../src/access/OwnableTL.sol";

contract MockOwnableTL is OwnableTL {

    uint256 public number;

    constructor() OwnableTL() {
        number = 1;
    }

    function gatedFunction(uint256 newNumber) external onlyOwner {
        number = newNumber;
    }

}