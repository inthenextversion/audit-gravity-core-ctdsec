// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Share is ERC20, Ownable {
    constructor() ERC20("Gravity Finance Farm Share Token", "GFI-ST"){}

    function mint(address to, uint _amount) external onlyOwner returns(bool){
        _mint(to, _amount);
        return true;
    }

    function burn(address from, uint _amount) external onlyOwner returns(bool){
        _burn(from, _amount);
        return true;
    }

}