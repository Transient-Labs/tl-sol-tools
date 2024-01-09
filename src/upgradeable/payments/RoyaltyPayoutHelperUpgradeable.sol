// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRoyaltyEngineV1} from "royalty-registry-solidity/IRoyaltyEngineV1.sol";
import {TransferHelper} from "../../payments/TransferHelper.sol";
import {SanctionsComplianceUpgradeable} from "../../upgradeable/payments/SanctionsComplianceUpgradeable.sol";

/// @title Royalty Payout Helper
/// @notice Abstract contract to help payout royalties using the Royalty Registry
/// @dev Does not manage updating the sanctions oracle and expects the child contract to implement
/// @author transientlabs.xyz
/// @custom:version 3.0.0
abstract contract RoyaltyPayoutHelperUpgradeable is SanctionsComplianceUpgradeable, TransferHelper {
    /*//////////////////////////////////////////////////////////////////////////
                                    Storage
    //////////////////////////////////////////////////////////////////////////*/

    /// @custom:storage-location erc7201:transientlabs.storage.RoyaltyPayoutHelper
    struct RoyaltyPayoutHelperStorage {
        address weth;
        IRoyaltyEngineV1 royaltyEngine;
    }

    // keccak256(abi.encode(uint256(keccak256("transientlabs.storage.RoyaltyPayoutHelper")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant RoyaltyPayoutHelperStorageLocation =
        0x9ab1d1ca9bfa2c669468b724939724262b3f2887db3df18c90168701d6422700;

    function _getRoyaltyPayoutHelperStorage() private pure returns (RoyaltyPayoutHelperStorage storage $) {
        assembly {
            $.slot := RoyaltyPayoutHelperStorageLocation
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Initializer
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to initialize the contract
    /// @param sanctionsOracle - the init sanctions oracle
    /// @param wethAddress - the init weth address
    /// @param royaltyEngineAddress - the init royalty engine address
    function __RoyaltyPayoutHelper_init(address sanctionsOracle, address wethAddress, address royaltyEngineAddress)
        internal
        onlyInitializing
    {
        __RoyaltyPayoutHelper_init_unchained(wethAddress, royaltyEngineAddress);
        __SanctionsCompliance_init(sanctionsOracle);
    }

    /// @notice unchained function to initialize the contract
    /// @param wethAddress - the init weth address
    /// @param royaltyEngineAddress - the init royalty engine address
    function __RoyaltyPayoutHelper_init_unchained(address wethAddress, address royaltyEngineAddress)
        internal
        onlyInitializing
    {
        RoyaltyPayoutHelperStorage storage $ = _getRoyaltyPayoutHelperStorage();
        $.weth = wethAddress;
        $.royaltyEngine = IRoyaltyEngineV1(royaltyEngineAddress);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Internal State Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to update the WETH address
    /// @dev Care should be taken to ensure proper access control for this function
    /// @param wethAddress The new WETH token address
    function _setWethAddress(address wethAddress) internal {
        RoyaltyPayoutHelperStorage storage $ = _getRoyaltyPayoutHelperStorage();
        $.weth = wethAddress;
    }

    /// @notice Function to update the royalty engine address
    /// @dev Care should be taken to ensure proper access control for this function
    /// @param royaltyEngineAddress The new royalty engine address
    function _setRoyaltyEngineAddress(address royaltyEngineAddress) internal {
        RoyaltyPayoutHelperStorage storage $ = _getRoyaltyPayoutHelperStorage();
        $.royaltyEngine = IRoyaltyEngineV1(royaltyEngineAddress);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Royalty Payout Function
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to payout royalties from the contract balance based on sale price
    /// @dev if the call to the royalty engine reverts or if the return values are invalid, no payments are made
    /// @dev if the sum of the royalty payouts is greater than the salePrice, the loop exits early for gas savings (this shouldn't happen in reality)
    /// @dev if this is used in a call where tokens should be transferred from a sender, it is advisable to
    ///      first transfer the required amount to the contract and then call this function, as it will save on gas
    /// @param token The contract address for the token
    /// @param tokenId The token id
    /// @param currency The address of the currency to send to recipients (null address == ETH)
    /// @param salePrice The sale price for the token
    /// @return remainingSale The amount left over in the sale after paying out royalties
    function _payoutRoyalties(address token, uint256 tokenId, address currency, uint256 salePrice)
        internal
        returns (uint256 remainingSale)
    {
        RoyaltyPayoutHelperStorage storage $ = _getRoyaltyPayoutHelperStorage();
        remainingSale = salePrice;
        if (address($.royaltyEngine).code.length == 0) return remainingSale;
        try $.royaltyEngine.getRoyalty(token, tokenId, salePrice) returns (
            address payable[] memory recipients, uint256[] memory amounts
        ) {
            if (recipients.length != amounts.length) return remainingSale;

            for (uint256 i = 0; i < recipients.length; i++) {
                if (_isSanctioned(recipients[i], false)) continue; // don't pay to sanctioned addresses
                if (amounts[i] > remainingSale) break;
                remainingSale -= amounts[i];
                if (currency == address(0)) {
                    _safeTransferETH(recipients[i], amounts[i], $.weth);
                } else {
                    _safeTransferERC20(recipients[i], currency, amounts[i]);
                }
            }

            return remainingSale;
        } catch {
            return remainingSale;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Public View Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to get the current WETH address
    function weth() public view returns (address) {
        RoyaltyPayoutHelperStorage storage $ = _getRoyaltyPayoutHelperStorage();
        return $.weth;
    }

    /// @notice Function to get the royalty registry
    function royaltyEngine() public view returns (IRoyaltyEngineV1) {
        RoyaltyPayoutHelperStorage storage $ = _getRoyaltyPayoutHelperStorage();
        return $.royaltyEngine;
    }
}
