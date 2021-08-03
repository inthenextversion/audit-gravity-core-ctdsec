// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IIDOFactory {
    function whitelist(address _address) external view returns (bool);
    function priceOracle() external view returns(address);
    function slippage() external view returns(uint);
    function governance() external view returns (address);
    function gfi() external view returns (address);
    function weth() external view returns (address);
    function usdc() external view returns (address);
    function tierChecker() external view returns (address);
    function swapRouter() external view returns (address);
    function swapFactory() external view returns (address);
    function feeManager() external view returns (address);
    function deployFarm(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external;
    function deployCompounder(address _farmAddress, address _depositToken, address _rewardToken, uint _maxCallerReward, uint _callerFee, uint _minHarvest, bool _lpFarm, address _lpA, address _lpB) external;
    function farmFactory() external view returns(address);
}