// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
import '../DeFi/uniswapv2/interfaces/IUniswapV2Pair.sol';
import '../DeFi/uniswapv2/interfaces/IERC20.sol';
contract SwapCaller {
    function makeSwap(address token, address pairAddress, uint amountOut0, uint amountOut1, uint amountIn) public{
        IERC20Uniswap(token).transferFrom(msg.sender, pairAddress, amountIn);
        IUniswapV2Pair(pairAddress).swap(amountOut0, amountOut1, msg.sender, new bytes(0)); 
    }
}