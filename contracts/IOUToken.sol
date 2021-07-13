// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IOUToken is ERC20, Ownable {
    
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}
    
    function mintIOU( address _address, uint _amount) external onlyOwner{
        _mint(_address, _amount);
    }
    
    function burnIOU(address _address, uint _amount) external onlyOwner {
        _burn(_address, _amount);
    }
}