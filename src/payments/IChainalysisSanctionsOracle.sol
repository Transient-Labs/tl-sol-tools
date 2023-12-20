// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IChainalysisSanctionsOracle {
    function isSanctioned(address addr) external view returns (bool);
}
