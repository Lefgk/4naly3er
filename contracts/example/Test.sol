// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

contract KotF {
    address payable public currentFool;
    uint256 public currentPrice;

    error Unauthorized();
    error WrongValue();
    error FailedEtherTransfer();

    event NewFool(address indexed newfool, uint256 indexed newprice);

    /**
     * @notice handle accidental Ether sent to this contract
     */
    receive() external payable {
        revert Unauthorized();
    }

    /**
     * @notice function to become next fool
     */
    function BecomeFool() external payable {
        if (currentPrice == 0) {
            if (msg.value == 0) revert FailedEtherTransfer();
            // require(msg.value != 0 , "Ether amount sent is wrong");
        } else {
            if (2 * msg.value < currentPrice * 3) revert WrongValue();
            // "Ether amount not enough"

            (bool sent, ) = address(currentFool).call{ value: msg.value }("");
            if (!sent) revert FailedEtherTransfer();
        }
        currentFool = payable(msg.sender);
        currentPrice = msg.value;

        emit NewFool(msg.sender, msg.value);
    }
}
