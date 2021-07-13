// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(address addr1, address addr2, address addr3, address addr4) ERC20("Mock Token", "MOCK"){
        _mint(addr1, 100000 * (10 ** 18));
        _mint(addr2, 100000 * (10 ** 18));
        _mint(addr3, 100000 * (10 ** 18));
        _mint(addr4, 100000 * (10 ** 18));
    }
}