// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std-1.9.4/Test.sol";
import {Strings} from "@openzeppelin-contracts-5.0.2/utils/Strings.sol";
import {Receiver, RevertingReceiver} from "test/utils/Receivers.sol";
import {WETH9} from "test/utils/WETH9.sol";
import {MockERC20, MockERC20WithFee} from "test/utils/MockERC20.sol";
import {RoyaltyPayoutHelper, IRoyaltyEngineV1} from "src/payments/RoyaltyPayoutHelper.sol";
import {IChainalysisSanctionsOracle} from "src/payments/IChainalysisSanctionsOracle.sol";

contract ExternalRoyaltyPayoutHelper is RoyaltyPayoutHelper {
    constructor(address sanctionsAddress, address wethAddress, address royaltyEngineAddress)
        RoyaltyPayoutHelper(sanctionsAddress, wethAddress, royaltyEngineAddress)
    {}

    function setWethAddress(address wethAddress) external {
        _setWethAddress(wethAddress);
    }

    function setRoyaltyEngineAddress(address royaltyEngineAddress) external {
        _setRoyaltyEngineAddress(royaltyEngineAddress);
    }

    function payoutRoyalties(address token, uint256 tokenId, address currency, uint256 salePrice)
        external
        returns (uint256)
    {
        return _payoutRoyalties(token, tokenId, currency, salePrice);
    }

    function updateSanctionsOracle(address newOracle) external {
        _updateSanctionsOracle(newOracle);
    }
}

contract TestRoyaltyPayoutHelper is Test {
    using Strings for uint256;

    ExternalRoyaltyPayoutHelper rph;
    address weth;
    address receiver;
    address revertingReceiver;
    MockERC20 erc20;
    MockERC20WithFee erc20fee;

    address royaltyEngine = 0x0385603ab55642cb4Dd5De3aE9e306809991804f;

    address ben = address(0x0BEEF);
    address chris = address(0xC0FFEE);
    address david = address(0x1D1B);

    function setUp() public {
        weth = address(new WETH9());
        receiver = address(new Receiver());
        revertingReceiver = address(new RevertingReceiver());
        erc20 = new MockERC20(ben);
        erc20fee = new MockERC20WithFee(ben);

        rph = new ExternalRoyaltyPayoutHelper(address(0), weth, royaltyEngine);
    }

    function test_Init() public view {
        assert(rph.weth() == weth);
        assert(address(rph.royaltyEngine()) == royaltyEngine);
    }

    function test_UpdateWethAddress(address newWeth) public {
        rph.setWethAddress(newWeth);
        assert(rph.weth() == newWeth);
    }

    function test_UpdateRoyaltyEngine(address newRoyaltyEngine) public {
        rph.setRoyaltyEngineAddress(newRoyaltyEngine);
        assert(address(rph.royaltyEngine()) == newRoyaltyEngine);
    }

    function test_PayoutRoyaltiesEOA(uint256 salePrice) public {
        uint256 remainingSale = rph.payoutRoyalties(address(1), 1, address(0), salePrice);
        assert(remainingSale == salePrice);
    }

    function test_PayoutRoyaltiesRevertingQuery(uint256 salePrice) public {
        vm.mockCallRevert(royaltyEngine, abi.encodeWithSelector(IRoyaltyEngineV1.getRoyalty.selector), "fail fail");

        uint256 remainingSale = rph.payoutRoyalties(address(1), 1, address(0), salePrice);
        assert(remainingSale == salePrice);

        vm.clearMockedCalls();
    }

    function test_PayoutRoyaltiesUnequalLengthArrays(uint256 salePrice) public {
        address[] memory recipients = new address[](1);
        recipients[0] = address(1);
        uint256[] memory amounts = new uint256[](0);
        vm.mockCall(
            royaltyEngine, abi.encodeWithSelector(IRoyaltyEngineV1.getRoyalty.selector), abi.encode(recipients, amounts)
        );

        uint256 remainingSale = rph.payoutRoyalties(address(1), 1, address(0), salePrice);
        assert(remainingSale == salePrice);

        vm.clearMockedCalls();
    }

    function test_PayoutRoyaltiesZeroLengthArrays(uint256 salePrice) public {
        address[] memory recipients = new address[](0);
        uint256[] memory amounts = new uint256[](0);
        vm.mockCall(
            royaltyEngine, abi.encodeWithSelector(IRoyaltyEngineV1.getRoyalty.selector), abi.encode(recipients, amounts)
        );

        uint256 remainingSale = rph.payoutRoyalties(address(1), 1, address(0), salePrice);
        assert(remainingSale == salePrice);

        vm.clearMockedCalls();
    }

    function test_PayoutRoyaltiesMoreThanSalePrice() public {
        uint256 price = 1 ether;
        address[] memory recipients = new address[](2);
        recipients[0] = address(100);
        recipients[1] = address(101);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 0.9 ether;
        amounts[1] = 0.2 ether;

        vm.deal(address(rph), price);

        vm.mockCall(
            royaltyEngine, abi.encodeWithSelector(IRoyaltyEngineV1.getRoyalty.selector), abi.encode(recipients, amounts)
        );

        uint256 remainingSale = rph.payoutRoyalties(address(1), 1, address(0), price);
        assert(address(100).balance == 0.9 ether);
        assert(remainingSale == 0.1 ether);

        vm.clearMockedCalls();
    }

    function test_PayoutRoyaltiesETH(uint8 numRecipients, uint256 salePrice, bool sanctionsCompliance) public {
        vm.assume(salePrice > 4);
        vm.assume(numRecipients > 0);
        vm.assume(salePrice >= numRecipients);
        uint256 price = salePrice / numRecipients;
        address[] memory recipients = new address[](numRecipients);
        uint256[] memory amounts = new uint256[](numRecipients);
        uint256 remainingAmount = salePrice;
        for (uint256 i = 0; i < numRecipients; i++) {
            remainingAmount -= price;
            amounts[i] = price;
            recipients[i] = makeAddr(i.toString());
        }

        vm.mockCall(
            royaltyEngine, abi.encodeWithSelector(IRoyaltyEngineV1.getRoyalty.selector), abi.encode(recipients, amounts)
        );

        if (sanctionsCompliance) {
            address newOracle = makeAddr("Sanctions compliance is soooooo fun");
            rph.updateSanctionsOracle(newOracle);
            vm.mockCall(
                newOracle, abi.encodeWithSelector(IChainalysisSanctionsOracle.isSanctioned.selector), abi.encode(true)
            );
        }

        vm.deal(address(rph), salePrice);

        uint256 remainingSale = rph.payoutRoyalties(address(1), 1, address(0), salePrice);

        if (sanctionsCompliance) {
            assert(remainingSale == salePrice);
            for (uint256 i = 0; i < numRecipients; i++) {
                assert(recipients[i].balance == 0);
            }
        } else {
            assert(remainingAmount == remainingSale);
            for (uint256 i = 0; i < numRecipients; i++) {
                assert(recipients[i].balance == price);
            }
        }

        vm.clearMockedCalls();
    }

    function test_PayoutRoyaltiesERC20(uint8 numRecipients, uint256 salePrice, bool sanctionsCompliance) public {
        vm.assume(salePrice > 4);
        vm.assume(numRecipients > 0);
        vm.assume(salePrice >= numRecipients);
        uint256 price = salePrice / numRecipients;
        address[] memory recipients = new address[](numRecipients);
        uint256[] memory amounts = new uint256[](numRecipients);
        uint256 remainingAmount = salePrice;
        for (uint256 i = 0; i < numRecipients; i++) {
            remainingAmount -= price;
            amounts[i] = price;
            recipients[i] = makeAddr(i.toString());
        }

        vm.mockCall(
            royaltyEngine, abi.encodeWithSelector(IRoyaltyEngineV1.getRoyalty.selector), abi.encode(recipients, amounts)
        );

        if (sanctionsCompliance) {
            address newOracle = makeAddr("Sanctions compliance is soooooo fun");
            rph.updateSanctionsOracle(newOracle);
            vm.mockCall(
                newOracle, abi.encodeWithSelector(IChainalysisSanctionsOracle.isSanctioned.selector), abi.encode(true)
            );
        }

        vm.prank(ben);
        erc20.transfer(address(rph), salePrice);

        uint256 remainingSale = rph.payoutRoyalties(address(1), 1, address(erc20), salePrice);

        if (sanctionsCompliance) {
            assert(remainingSale == salePrice);
            for (uint256 i = 0; i < numRecipients; i++) {
                assert(erc20.balanceOf(recipients[i]) == 0);
            }
        } else {
            assert(remainingAmount == remainingSale);
            for (uint256 i = 0; i < numRecipients; i++) {
                assert(erc20.balanceOf(recipients[i]) == price);
            }
        }

        vm.clearMockedCalls();
    }

    function test_PayoutRoyaltiesERC20WithFee(uint8 numRecipients, uint128 salePrice) public {
        vm.assume(salePrice > 4);
        vm.assume(numRecipients > 0);
        vm.assume(salePrice >= numRecipients);
        uint256 price = uint256(salePrice) / numRecipients;
        address[] memory recipients = new address[](numRecipients);
        uint256[] memory amounts = new uint256[](numRecipients);
        uint256 remainingAmount = salePrice;
        for (uint256 i = 0; i < numRecipients; i++) {
            remainingAmount -= price;
            amounts[i] = price;
            recipients[i] = makeAddr(i.toString());
        }

        vm.mockCall(
            royaltyEngine, abi.encodeWithSelector(IRoyaltyEngineV1.getRoyalty.selector), abi.encode(recipients, amounts)
        );

        vm.prank(ben);
        erc20fee.transfer(address(rph), uint256(salePrice) + 1);

        uint256 remainingSale = rph.payoutRoyalties(address(1), 1, address(erc20fee), uint256(salePrice));
        assert(remainingAmount == remainingSale);
        for (uint256 i = 0; i < numRecipients; i++) {
            assert(erc20fee.balanceOf(recipients[i]) == price - 1);
        }

        vm.clearMockedCalls();
    }
}
