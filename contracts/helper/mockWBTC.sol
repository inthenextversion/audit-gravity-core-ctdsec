// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWBTC is ERC20 {
    constructor() ERC20("Mock wBTC", "MwBTC"){
    }

    function mintMeTokens() external {
        _mint(msg.sender, 1000 * 10**18);
    }
}