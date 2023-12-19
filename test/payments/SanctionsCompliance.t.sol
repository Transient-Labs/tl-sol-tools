// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SanctionsCompliance} from "src/payments/SanctionsCompliance.sol";
import {IChainalysisSanctionsOracle} from "src/payments/IChainalysisSanctionsOracle.sol";

contract SanctionsComplianceTest is Test, SanctionsCompliance {

    constructor() SanctionsCompliance(address(0)) {}

    function test_init(address sender) public view {
        assert(address(oracle) == address(0));
        assert(_isSanctioned(sender, false) == false);
    }

    function test_updateOracle(address newOracle) public {
        vm.expectEmit(true, true, false, false);
        emit SanctionsOracleUpdated(address(0), newOracle);
        _updateSanctionsOracle(newOracle);

        assert(address(oracle) == newOracle);
    }

    function isSanctioned(address sender, bool shouldRevert) external view returns(bool) {
        return _isSanctioned(sender, shouldRevert);
    }

    function test_isSanctioned(address sender, address newOracle, bool isSanctioned_, bool shouldRevert) public {
        vm.assume(sender != newOracle);
        vm.assume(bytes(newOracle.code).length == 0);
        vm.assume(newOracle != address(0));
        _updateSanctionsOracle(newOracle);

        vm.mockCall(newOracle, abi.encodeWithSelector(IChainalysisSanctionsOracle.isSanctioned.selector), abi.encode(isSanctioned_));

        if (isSanctioned_ && shouldRevert) {
            vm.expectRevert(SanctionedAddress.selector);
            this.isSanctioned(sender, shouldRevert);
        } else {
            assert(this.isSanctioned(sender, shouldRevert) == isSanctioned_);
        }

        vm.clearMockedCalls();
    }
}