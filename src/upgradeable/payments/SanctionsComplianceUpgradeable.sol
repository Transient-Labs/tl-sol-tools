// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {IChainalysisSanctionsOracle} from "src/payments/IChainalysisSanctionsOracle.sol";

/// @title Sanctions Compliance
/// @notice Abstract contract to comply with U.S. sanctioned addresses
/// @dev Uses the Chainalysis Sanctions Oracle for checking sanctions
/// @author transientlabs.xyz
/// @custom:version 3.0.0
contract SanctionsComplianceUpgradeable is Initializable {
    /*//////////////////////////////////////////////////////////////////////////
                                    Storage
    //////////////////////////////////////////////////////////////////////////*/

    /// @custom:storage-location erc7201:transientlabs.storage.SanctionsCompliance
    struct SanctionComplianceStorage {
        IChainalysisSanctionsOracle oracle;
    }

    // keccak256(abi.encode(uint256(keccak256("transientlabs.storage.SanctionsCompliance")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SanctionComplianceStorageLocation = 0xd66684c5a7747baca4a45cbf84c01526f3b53186fc4aea64a4c6e2fa4447c700;

    function _getSanctionsComplianceStorage() private pure returns (SanctionComplianceStorage storage $) {
        assembly {
            $.slot := SanctionComplianceStorageLocation
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////////////////*/

    event SanctionsOracleUpdated(address indexed prevOracle, address indexed newOracle);

    /*//////////////////////////////////////////////////////////////////////////
                                    Errors
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sanctioned address by OFAC
    error SanctionedAddress();

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to initialize the contract
    /// @param initOracle The initial oracle address
    function __SanctionsCompliance_init(address initOracle) internal onlyInitializing {
        __SanctionsCompliance_init_unchained(initOracle);
    }

    /// @notice unchained function to initialize the contract
    /// @param initOracle The initial oracle address
    function __SanctionsCompliance_init_unchained(address initOracle) internal onlyInitializing {
        _updateSanctionsOracle(initOracle);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Internal Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal function to change the sanctions oracle
    /// @param newOracle The new sanctions oracle address
    function _updateSanctionsOracle(address newOracle) internal {
        SanctionComplianceStorage storage $ = _getSanctionsComplianceStorage();
        address prevOracle = address($.oracle);
        $.oracle = IChainalysisSanctionsOracle(newOracle);

        emit SanctionsOracleUpdated(prevOracle, newOracle);
    }

    /// @notice Internal function to check the sanctions oracle for an address
    /// @dev Disable sanction checking by setting the oracle to the zero address
    /// @param sender The address that is trying to send money
    /// @param shouldRevertIfSanctioned A flag indicating if the call should revert if the sender is sanctioned. Set to false if wanting to get a result.
    /// @return isSanctioned Boolean indicating if the sender is sanctioned
    function _isSanctioned(address sender, bool shouldRevertIfSanctioned) internal view returns (bool isSanctioned) {
        SanctionComplianceStorage storage $ = _getSanctionsComplianceStorage();
        if (address($.oracle) == address(0)) {
            return false;
        }
        isSanctioned = $.oracle.isSanctioned(sender);
        if (shouldRevertIfSanctioned && isSanctioned) revert SanctionedAddress();
        return isSanctioned;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Public View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to get chainalysis oracle
    function oracle() public view returns(IChainalysisSanctionsOracle) {
        SanctionComplianceStorage storage $ = _getSanctionsComplianceStorage();
        return $.oracle;
    }
}
