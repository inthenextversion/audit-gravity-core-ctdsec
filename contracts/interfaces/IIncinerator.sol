// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IIncinerator {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function convertEarningsToGFIandBurn() external;
}