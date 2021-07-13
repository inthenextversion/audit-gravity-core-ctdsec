// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol@v4.1.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.1.0


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.1.0

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/interfaces/IFarm.sol



interface IFarm {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function withdrawRewards(uint256 amount) external;
    function transferOwnership(address newOwner) external; 
    function owner() external view returns(address);
}


// File contracts/FarmTimeLock.sol




contract FarmTimeLock is Ownable {

    uint public lockLength; //Amount of time that needs to pass in order for a request to become valid
    uint public graceLength; //Amount of time owner has to call the function before it expires

    //Set up as a mapping, so that owner can interact with multipe farm contracts simutaneously without needing to wait (farm_count * 1 week)
    //Instead owner waits 1 week
    mapping(address => uint) public transferOwnershipFromLock_timestamp;
    mapping(address => address) public transferOwnershipFromLock_newOwner;
    mapping(address => uint) public callWithdrawRewards_timestamp;
    mapping(address => uint) public callWithdrawRewards_amount; //The variable you want to pass into withdrawRewards function call
    uint public withdrawERC20_timestamp;
    address public withdrawERC20_token;
    address public withdrawERC20_wallet;

    /**
    * @dev emitted when proposal to change farm owner is made
    * @param valid the timestamp when the proposal will become valid
    * @param farm the address of the farm
    * @param newOwner the address of the new owner
    **/
    event transferOwnershipCalled(uint valid, address farm, address newOwner);
    
    /**
    * @dev emitted when proposal to call withdraw rewards is made
    * @param valid the timestamp when the proposal will become valid
    * @param farm the address of the farm
    * @param amount the amount of tokens to withdraw with 10**18 decimals
    **/
    event withdrawRewards(uint valid, address farm, uint amount);
    
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
    * @dev allows owner to call the transferOwnership function in any farm (that has it's owner set as this address) after the time lock period is up, and before the call expires
    * @param farm the address of the farm to call withdrawRewards on
    * @param newOwner the address of the new owner of the farm contract
    **/
    function transferOwnershipFromLock(address farm, address newOwner) external onlyOwner{
        require(IFarm(farm).owner() == address(this), "Time lock contract does not own farm contract!");
        uint validStart = transferOwnershipFromLock_timestamp[farm] + lockLength;
        uint validEnd = transferOwnershipFromLock_timestamp[farm] + lockLength + graceLength;

        if (block.timestamp > validStart && block.timestamp < validEnd){//If request is now valid fulfill it
            transferOwnershipFromLock_timestamp[farm] = 0; //reset the timestamp
            IFarm(farm).transferOwnership(transferOwnershipFromLock_newOwner[farm]);
        }

        else{ //Call is not valid so reset timestamp and capture input
            if(block.timestamp > validEnd){//Only make a new timestamp if the current one is expired
                transferOwnershipFromLock_timestamp[farm] = block.timestamp;
                transferOwnershipFromLock_newOwner[farm] = newOwner;
                emit transferOwnershipCalled(validStart, farm, newOwner);//emit for the world to see
            }
        }
    }

    /**
    * @dev allows owner to call the withdrawRewards function in any farm (that has it's owner set as this address) after the time lock period is up, and before the call expires
    * @param farm the address of the farm to call withdrawRewards on
    * @param amount the amount of tokens to withdraw from the pool
    **/
    function callWithdrawRewards(address farm, uint amount) external onlyOwner{
        require(IFarm(farm).owner() == address(this), "Time lock contract does not own farm contract!");
        uint validStart = callWithdrawRewards_timestamp[farm] + lockLength;
        uint validEnd = callWithdrawRewards_timestamp[farm] + lockLength + graceLength;

        if (block.timestamp > validStart && block.timestamp < validEnd){//If request is now valid fulfill it
            callWithdrawRewards_timestamp[farm] = 0; //reset the timestamp
            IFarm(farm).withdrawRewards(callWithdrawRewards_amount[farm]);
        }

        else{ //Call is not valid so reset timestamp and capture input
            if(block.timestamp > validEnd){//Only make a new timestamp if the current one is expired
                callWithdrawRewards_timestamp[farm] = block.timestamp;
                callWithdrawRewards_amount[farm] = amount;
                emit withdrawRewards(validStart, farm, amount);//emit for the world to see
            }
        }
    }

    /**
    * @dev allows owner to withdraw any ERC20 token from THIS contract, after waiting a week.
    * note, token address, and recieving wallet address are publically visible for the week up until the call is valid
    * @param token the address of the ERC20 token you want to withdraw from this contract
    * @param wallet the address of the reciever of withdrawn tokens
    **/
    function withdrawERC20(address token, address wallet) external onlyOwner{
        uint validStart = withdrawERC20_timestamp + lockLength;
        uint validEnd = withdrawERC20_timestamp + lockLength + graceLength;

        if (block.timestamp > validStart && block.timestamp < validEnd){//If request is now valid fulfill it
            withdrawERC20_timestamp = 0; //reset the timestamp
            IERC20 Token = IERC20(withdrawERC20_token);
            Token.transfer(withdrawERC20_wallet, Token.balanceOf(address(this)));
        }

        else{ //Call is not valid so reset timestamp and capture input
            if(block.timestamp > validEnd){//Only make a new timestamp if the current one is expired
                withdrawERC20_timestamp = block.timestamp;
                withdrawERC20_wallet = wallet;
                withdrawERC20_token = token;
                emit withdraw(validStart, token, wallet);//emit for the world to see
            }
        }
    }
}