// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ShareInfo{
    address depositToken;
    address rewardToken;
    address shareToken;
    uint minHarvest;
    uint maxCallerReward;
    uint callerFeePercent;
    bool lpFarm;
    address lpA; //only applies to lpFarms
    address lpB;
}

interface ICompounderFactory {

    function farmAddressToShareInfo(address farm) external view returns(ShareInfo memory);
    function tierManager() external view returns(address);
    function getFarm(address shareToken) external view returns(address);
    function gfi() external view returns(address);
    function swapFactory() external view returns(address);
}