// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ITierManager {
    function checkTier(address caller) external returns(uint);
}