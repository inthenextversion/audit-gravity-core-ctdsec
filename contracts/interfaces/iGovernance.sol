// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface iGovernance {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function delegateFee(address reciever) external returns (uint256);

    function claimFee() external returns (uint256);

    function tierLedger(address user) external returns(uint[3] memory);

    function depositFee(uint256 amountWETH, uint256 amountWBTC) external;
}