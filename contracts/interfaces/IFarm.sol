// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IFarm {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function withdrawRewards(uint256 amount) external;
    function transferOwnership(address newOwner) external; 
    function owner() external view returns(address);
}