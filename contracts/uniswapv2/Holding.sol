// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;

import "../interfaces/OZ_IERC20.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/iGovernance.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2ERC20.sol";
import "./interfaces/IPathOracle.sol";
import "./interfaces/IPriceOracle.sol";

//TODO make it so that the governance address is passed into the factory on craetion, then it is relayed to the pair contract and to this contract, and initialized in the
//TODO before any thing using the current pair cumulative, make sure getReserves() LastTimeStamp is equal to the current block.timestamp
//TODO maybe make it a modifier????
contract Holding {
    using SafeMathUniswap for uint256;

    address public SWAP_ADDRESS;

    modifier onlySwap() {
        require(msg.sender == SWAP_ADDRESS, "Gravity Finance: FORBIDDEN");
        _;
    }

    constructor() public {
        SWAP_ADDRESS = msg.sender;
    }

    function approveEM(address TOKEN_ADDRESS, address EM_ADDRESS, uint amount)external onlySwap{
        OZ_IERC20(TOKEN_ADDRESS).approve(EM_ADDRESS, amount);
    }
    
}
