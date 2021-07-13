// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFarmV2 {

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

    function withdrawRewards(uint256 amount) external;
    function transferOwnership(address newOwner) external; 
    function owner() external view returns(address);
    function init (address _rewardToken, uint256 _amount, address _lpToken, uint256 _blockReward, uint256 _startBlock, uint256 _endBlock, uint256 _bonusEndBlock, uint256 _bonus) external; 
    function pendingReward(address _user) external view returns (uint256);

    function userInfo(address user) external view returns (UserInfo memory);
    function farmInfo() external view returns (FarmInfo memory);
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    
}