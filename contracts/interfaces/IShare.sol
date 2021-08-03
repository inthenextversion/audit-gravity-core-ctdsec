// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IShare is IERC20{
    function mint(address to, uint _amount) external returns(bool);
    function burn(address from, uint _amount) external returns(bool);
    function initialize() external;
    function initializeERC20(string memory name_, string memory symbol_) external;
    function getSharesGFIWorthAtLastSnapshot(address _address) view external returns(uint);
}