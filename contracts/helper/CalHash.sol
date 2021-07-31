// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
import '../DeFi/uniswapv2/UniswapV2Pair.sol';

contract CalHash {
    function getInitHash() public pure returns(bytes32){
        bytes memory bytecode1 = type(UniswapV2Pair).creationCode;
        return keccak256(abi.encodePacked(bytecode1));
    }
}