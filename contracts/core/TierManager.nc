// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IShare.sol";
import "../interfaces/IFarmV2.sol";
import "../interfaces/ICompounderFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TierManager is ERC721, Ownable {
    mapping(address => mapping(uint => bool)) claimedThisSnapshot; //so users can not double claim
    mapping(address => mapping(address => bool)) supportedConversion; //bool set by owner to say that a compounder farm pair is valid

    constructor() ERC721("Gravity Finance IDO Ticket", "GFI-IDO-T"){}

    function updateSupportedConversion(address compounderFactory, address farm, bool status) external onlyOwner{
        supportedConversion[compounderFactory][farm] = status;
    }

    function mintTicketsFromActual() external{

    }

    function mintTicketsFromDerivatives(address compounderFactory, address farm) external {
        require(supportedConversion[compounderFactory][farm], 'Gravity Finance: Invalid Inputs');
    }

    function checkTier(address caller) external returns(uint){
        
    }
}