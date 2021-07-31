// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IFarm.sol";

contract WalletTimeLock is Ownable {

    uint public lockLength; //Amount of time that needs to pass in order for a request to become valid
    uint public graceLength; //Amount of time owner has to call the function before it expires

    mapping(address => uint) public withdrawERC20_timestamp;
    mapping(address => address) public withdrawERC20_token;
    mapping(address => uint) public withdrawERC20_amount;
    //mapping(address => address) public withdrawERC20_wallet;
    
    /**
    * @dev emitted when proposal to withdraw ERC20 tokens from this contract is made
    * @param token the token address of the token to withdraw
    * @param to the address of the wallet to send the tokens to
    **/
    event withdraw(uint valid, address token, address to);

    constructor(uint _lockLength, uint _graceLength){
        lockLength = _lockLength; // 1 week by default
        graceLength = _graceLength; //owner has 1 day to call the function once it is valid
    }

    /**
    * @dev allows owner to withdraw any ERC20 token from THIS contract, after waiting a week.
    * note, token address, and recieving wallet address are publically visible for the week up until the call is valid
    * @param token the address of the ERC20 token you want to withdraw from this contract
    * @param wallet the address of the reciever of withdrawn tokens
    **/
    function withdrawERC20(address token, address wallet, uint amount) external onlyOwner{
        uint validStart = withdrawERC20_timestamp[wallet] + lockLength;
        uint validEnd = withdrawERC20_timestamp[wallet] + lockLength + graceLength;

        if (block.timestamp > validStart && block.timestamp < validEnd){//If request is now valid fulfill it
            withdrawERC20_timestamp[wallet] = 0; //reset the timestamp
            IERC20 Token = IERC20(withdrawERC20_token[wallet]);
            Token.transfer(wallet, withdrawERC20_amount[wallet]);
        }

        else{ //Call is not valid so reset timestamp and capture input
            if(block.timestamp > validEnd){//Only make a new timestamp if the current one is expired
                withdrawERC20_timestamp[wallet] = block.timestamp;
                //withdrawERC20_wallet = wallet;
                withdrawERC20_amount[wallet] = amount;
                withdrawERC20_token[wallet] = token;
                emit withdraw(validStart, token, wallet);//emit for the world to see
            }
        }
    }
}