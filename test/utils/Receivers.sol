// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Receiver {
    event EthReceived(uint256 indexed amount);

    receive() external payable {
        emit EthReceived(msg.value);
    }
}

contract RevertingReceiver {
    receive() external payable {
        revert("you shall not pass");
    }
}

contract GriefingReceiver {
    event Grief();
    receive() external payable {
        for (uint256 i = 0; i < type(uint256).max; i++) {
            emit Grief();
        }
    }
}