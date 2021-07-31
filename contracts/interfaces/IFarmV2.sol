// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct UserInfo {
        uint256 amount;     // LP tokens provided.
        uint256 rewardDebt; // Reward debt.
}

struct FarmInfo {
    IERC20 lpToken;
    IERC20 rewardToken;
    uint startBlock;
    uint blockReward;
    uint bonusEndBlock;
    uint bonus;
    uint endBlock;
    uint lastRewardBlock;  // Last block number that reward distribution occurs.
    uint accRewardPerShare; // rewards per share, times 1e12
    uint farmableSupply; // total amount of tokens farmable
    uint numFarmers; // total amount of farmers
}

interface IFarmV2 {

    function initialize() external;
    function withdrawRewards(uint256 amount) external;
    function FarmFactory() external view returns(address);
    function init(address depositToken, address rewardToken, uint amount, uint blockReward, uint start, uint end, uint bonusEnd, uint bonus) external; 
    function pendingReward(address _user) external view returns (uint256);

    function userInfo(address user) external view returns (UserInfo memory);
    function farmInfo() external view returns (FarmInfo memory);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    
}