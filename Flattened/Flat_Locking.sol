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


// File contracts/Locking.sol



contract Locking is Ownable {
    mapping(address => uint256) public GFIbalance;
    mapping(address => uint256) public withdrawableFee;
    address[] public users;
    uint256 public userCount;
    uint256 public totalBalance;
    uint256 public lastFeeUpdate; // Timestamp for when updateWithdrawableFee() was last called
    IERC20 GFI;
    IERC20 WETH;
    iGovernance Governor;
    address public GOVERANCE_ADDRESS;
    uint256 public LockStart;
    uint256 public LockEnd;
    bool public stopFeeCollection;

    constructor(
        address GFI_ADDRESS,
        address WETH_ADDRESS,
        address _GOVERNANCE_ADDRESS
    ) {
        GFI = IERC20(GFI_ADDRESS);
        WETH = IERC20(WETH_ADDRESS);
        GOVERANCE_ADDRESS = _GOVERNANCE_ADDRESS;
        Governor = iGovernance(GOVERANCE_ADDRESS);
        LockStart = block.timestamp;
        LockEnd = LockStart + 31536000; //One year from contract deployment
    }

    function setGovenorAddress(address _address) external onlyOwner {
        GOVERANCE_ADDRESS = _address;
        Governor = iGovernance(GOVERANCE_ADDRESS);
    }

    function setFeeCollectionBool(bool _bool) external onlyOwner {
        stopFeeCollection = _bool;
    }

    function getLastFeeUpdate() external view returns (uint256) {
        return lastFeeUpdate;
    }

    /** @dev Allows owner to add new allowances for users
     * Address must not have an existing GFIbalance
     */
    function addUser(address _address, uint256 bal) external onlyOwner {
        require(GFIbalance[_address] == 0, "User is already in the contract!");
        require(
            GFI.transferFrom(msg.sender, address(this), bal),
            "GFI transferFrom failed!"
        );
        GFIbalance[_address] = bal;
        users.push(_address);
        userCount++;
        totalBalance = totalBalance + bal;
    }

    function updateWithdrawableFee() external {
        require(stopFeeCollection, "Fee distribution has been turned off!");
        uint256 collectedFee = Governor.claimFee();
        uint256 callersFee = collectedFee / 100;
        collectedFee = collectedFee - callersFee;
        uint256 userShare;
        for (uint256 i = 0; i < userCount; i++) {
            userShare = (collectedFee * GFIbalance[users[i]]) / totalBalance;
            //Remove last digit of userShare
            userShare = userShare / 10;
            userShare = userShare * 10;
            withdrawableFee[users[i]] = withdrawableFee[users[i]] + userShare;
        }
        lastFeeUpdate = block.timestamp;
        require(
            WETH.transfer(msg.sender, callersFee),
            "Failed to transfer callers fee to caller!"
        );
    }

    function collectFee() external {
        require(stopFeeCollection, "Fee distribution has been turned off!");
        require(withdrawableFee[msg.sender] > 0, "Caller has no fee to claim!");
        uint256 tmpBal = withdrawableFee[msg.sender];
        withdrawableFee[msg.sender] = 0;
        require(WETH.transfer(msg.sender, tmpBal));
    }

    function claimGFI() external {
        require(GFIbalance[msg.sender] > 0, "Caller has no GFI to claim!");
        require(block.timestamp > LockEnd, "GFI tokens are not fully vested!");
        uint256 tmpBal = GFIbalance[msg.sender];
        GFIbalance[msg.sender] = 0;
        require(
            GFI.transfer(msg.sender, tmpBal),
            "Failed to transfer GFI to caller!"
        );
    }

    function withdrawAll() external onlyOwner {
        require(block.timestamp > (LockEnd + 2592000), "Locking Period is not over yet!"); // If users have not claimed GFI 1 month after lock is done, Owner can claim remaining GFI and WETH in contract
        require(
            WETH.transferFrom(
                address(this),
                msg.sender,
                WETH.balanceOf(address(this))
            ),
            "Failed to transfer WETH to Owner!"
        );
        require(
            GFI.transferFrom(
                address(this),
                msg.sender,
                GFI.balanceOf(address(this))
            ),
            "Failed to transfer leftover GFI to Owner!"
        );
    }
}

interface iGovernance {
    /**
     * Assume claimFee uses msg.sender, and returns the amount of WETH sent to the caller
     */
    function claimFee() external returns (uint256);
}