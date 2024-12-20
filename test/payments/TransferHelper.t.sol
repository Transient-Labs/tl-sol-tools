// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std-1.9.4/Test.sol";
import {IERC20} from "@openzeppelin-contracts-5.0.2/token/ERC20/IERC20.sol";
import {Receiver, RevertingReceiver, GriefingReceiver} from "test/utils/Receivers.sol";
import {WETH9} from "test/utils/WETH9.sol";
import {MockERC20, MockERC20WithFee} from "test/utils/MockERC20.sol";
import {TransferHelper} from "src/payments/TransferHelper.sol";

contract ExternalTransferHelper is TransferHelper {
    function safeTransferETH(address recipient, uint256 amount, address weth) external {
        _safeTransferETH(recipient, amount, weth);
    }

    function safeTransferETHWithGasLimit(address recipient, uint256 amount, address weth, uint256 gasLimit) external {
        _safeTransferETH(recipient, amount, weth, gasLimit);
    }

    function safeTransferERC20(address recipient, address currency, uint256 amount) external {
        _safeTransferERC20(recipient, currency, amount);
    }

    function safeTransferFromERC20(address sender, address recipient, address currency, uint256 amount) external {
        _safeTransferFromERC20(sender, recipient, currency, amount);
    }
}

contract TestTransferHelper is Test {
    ExternalTransferHelper th;
    address weth;
    address receiver;
    address revertingReceiver;
    address griefingReceiver;
    MockERC20 erc20;
    MockERC20WithFee erc20fee;

    address ben = address(0x0BEEF);
    address chris = address(0xC0FFEE);
    address david = address(0x1D1B);

    function setUp() public {
        th = new ExternalTransferHelper();
        weth = address(new WETH9());
        receiver = address(new Receiver());
        revertingReceiver = address(new RevertingReceiver());
        griefingReceiver = address(new GriefingReceiver());
        erc20 = new MockERC20(ben);
        erc20fee = new MockERC20WithFee(ben);
    }

    function test_SafeTransferETH(address recipient, uint256 amount) public {
        vm.assume(recipient.code.length == 0 && recipient > address(100));

        vm.assume(amount < 1_000_000_000_000_000_000 ether);

        // test contract receiver
        vm.deal(address(th), amount);
        uint256 b1 = receiver.balance;
        th.safeTransferETH(receiver, amount, weth);
        assert(receiver.balance - b1 == amount);

        // test recipient
        vm.deal(address(th), amount);
        uint256 b2 = recipient.balance;
        th.safeTransferETH(recipient, amount, weth);
        assert(recipient.balance - b2 == amount);

        // test reverting receiver
        vm.deal(address(th), amount);
        uint256 b3 = IERC20(weth).balanceOf(revertingReceiver);
        th.safeTransferETH(revertingReceiver, amount, weth);
        assert(IERC20(weth).balanceOf(revertingReceiver) - b3 == amount);

        // test griefing receiver
        vm.deal(address(th), amount);
        uint256 b4 = IERC20(weth).balanceOf(griefingReceiver);
        th.safeTransferETH(griefingReceiver, amount, weth);
        assert(IERC20(weth).balanceOf(griefingReceiver) - b4 == amount);
    }

    function test_SafeTransferETHWithGasLimit(address recipient, uint256 amount) public {
        vm.assume(recipient.code.length == 0 && recipient > address(100));

        vm.assume(amount < 1_000_000_000_000_000_000 ether);

        // test contract receiver
        vm.deal(address(th), amount);
        uint256 b1 = receiver.balance;
        th.safeTransferETHWithGasLimit(receiver, amount, weth, 1e4);
        assert(receiver.balance - b1 == amount);

        // test recipient
        vm.deal(address(th), amount);
        uint256 b2 = recipient.balance;
        th.safeTransferETHWithGasLimit(recipient, amount, weth, 1e4);
        assert(recipient.balance - b2 == amount);

        // test reverting receiver
        vm.deal(address(th), amount);
        uint256 b3 = IERC20(weth).balanceOf(revertingReceiver);
        th.safeTransferETHWithGasLimit(revertingReceiver, amount, weth, 1e4);
        assert(IERC20(weth).balanceOf(revertingReceiver) - b3 == amount);

        // test griefing receiver
        vm.deal(address(th), amount);
        uint256 b4 = IERC20(weth).balanceOf(griefingReceiver);
        th.safeTransferETHWithGasLimit(griefingReceiver, amount, weth, 1e4);
        assert(IERC20(weth).balanceOf(griefingReceiver) - b4 == amount);
    }

    function test_SafeTransferERC20(address recipient, uint256 amount) public {
        vm.assume(recipient != address(0) && recipient != address(th) && amount > 0);

        // fund contract
        vm.prank(ben);
        erc20.transfer(address(th), amount);

        // test amount with regular ERC20
        uint256 b1 = erc20.balanceOf(recipient);
        th.safeTransferERC20(recipient, address(erc20), amount);
        assert(erc20.balanceOf(recipient) - b1 == amount);

        if (amount > 1) {
            // fund contract
            vm.prank(ben);
            erc20fee.transfer(address(th), amount);

            // test amount with token tax ERC20
            uint256 b2 = erc20fee.balanceOf(recipient);
            th.safeTransferERC20(recipient, address(erc20fee), amount - 1);
            assert(erc20fee.balanceOf(recipient) - b2 == amount - 2);
        }
    }

    function test_SafeTransferFromERC20(address recipient, uint256 amount) public {
        vm.assume(recipient != address(0));
        vm.assume(recipient != address(th));
        vm.assume(recipient != chris);
        vm.assume(amount > 0);

        // fund chris
        vm.prank(ben);
        erc20.transfer(chris, amount);

        // test failure for allowance
        vm.expectRevert();
        th.safeTransferFromERC20(chris, recipient, address(erc20), amount);

        // give allowance
        vm.prank(chris);
        erc20.approve(address(th), amount);

        // test amount with regular ERC20
        uint256 b1 = erc20.balanceOf(recipient);
        th.safeTransferFromERC20(chris, recipient, address(erc20), amount);
        if (recipient != chris) {
            assert(erc20.balanceOf(recipient) - b1 == amount);
        } else {
            assert(erc20.balanceOf(recipient) == b1);
        }

        if (amount > 1) {
            // fund chris
            vm.prank(ben);
            erc20fee.transfer(chris, amount);

            // test failure for allowance
            vm.expectRevert();
            th.safeTransferFromERC20(chris, recipient, address(erc20fee), amount - 1);

            // give allowance
            vm.prank(chris);
            erc20fee.approve(address(th), amount - 1);

            // test amount with token tax ERC20
            vm.expectRevert(TransferHelper.InsufficentERC20Transfer.selector);
            th.safeTransferFromERC20(chris, recipient, address(erc20fee), amount - 1);
        }
    }
}
