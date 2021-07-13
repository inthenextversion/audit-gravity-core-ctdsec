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


// File @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol@v4.1.0



/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol@v4.1.0


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol@v4.1.0



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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File contracts/interfaces/iGravityToken.sol


interface iGravityToken is IERC20 {

    function setGovernanceAddress(address _address) external;

    function changeGovernanceForwarding(bool _bool) external;

    function burn(uint256 _amount) external returns (bool);
}


// File contracts/Governance.sol






contract GovernanceV1 is Initializable, OwnableUpgradeable {
    mapping(address => uint256) public feeBalance;
    address public tokenAddress;
    struct FeeLedger {
        uint256 totalFeeCollected_LastClaim;
        uint256 totalSupply_LastClaim;
        uint256 userBalance_LastClaim;
    }
    mapping(address => FeeLedger) public feeLedger;
    uint256 totalFeeCollected;
    iGravityToken GFI;
    IERC20 WETH;
    IERC20 WBTC;

    modifier onlyToken() {
        require(msg.sender == tokenAddress, "Only the token contract can call this function");
        _;
    }

    function initialize(
        address GFI_ADDRESS,
        address WETH_ADDRESS,
        address WBTC_ADDRESS
    ) public initializer {
        __Ownable_init();
        tokenAddress = GFI_ADDRESS;
        GFI = iGravityToken(GFI_ADDRESS);
        WETH = IERC20(WETH_ADDRESS);
        WBTC = IERC20(WBTC_ADDRESS);
    }
    /**
    * @dev internal function called when token contract calls govAuthTransfer or govAuthTransferFrom
    * Will update the recievers fee balance. This will not change the reward they would have got from this fee update
    * rather it updates the fee ledger to refelct the new increased amount of GFI in their wallet
    * @param _address the address of the address recieving GFI tokens
    * @param amount the amount of tokens the address is recieving
    **/
    function _updateFeeReceiver(address _address, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 supply;
        uint256 balance;

        //Pick the greatest supply and the lowest user balance
        uint256 currentBalance = GFI.balanceOf(_address) + amount; //Add the amount they are getting transferred eventhough updateFee will use smaller pre transfer value
        if (currentBalance > feeLedger[_address].userBalance_LastClaim) {
            balance = feeLedger[_address].userBalance_LastClaim;
        } else {
            balance = currentBalance;
        }

        uint256 currentSupply = GFI.totalSupply();
        if (currentSupply < feeLedger[_address].totalSupply_LastClaim) {
            supply = feeLedger[_address].totalSupply_LastClaim;
        } else {
            supply = currentSupply;
        }

        uint256 feeAllocation =
            ((totalFeeCollected -
                feeLedger[_address].totalFeeCollected_LastClaim) * balance) /
                supply;
        feeLedger[_address].totalFeeCollected_LastClaim = totalFeeCollected;
        feeLedger[_address].totalSupply_LastClaim = currentSupply;
        feeLedger[_address].userBalance_LastClaim = currentBalance;
        feeBalance[_address] = feeBalance[_address] + feeAllocation;
        return feeAllocation;
    }

    function updateFee(address _address) public returns (uint256) {
        require(GFI.balanceOf(_address) > 0, "_address has no GFI");
        uint256 supply;
        uint256 balance;

        //Pick the greatest supply and the lowest user balance
        uint256 currentBalance = GFI.balanceOf(_address);
        if (currentBalance > feeLedger[_address].userBalance_LastClaim) {
            balance = feeLedger[_address].userBalance_LastClaim;
        } else {
            balance = currentBalance;
        }

        uint256 currentSupply = GFI.totalSupply();
        if (currentSupply < feeLedger[_address].totalSupply_LastClaim) {
            supply = feeLedger[_address].totalSupply_LastClaim;
        } else {
            supply = currentSupply;
        }

        uint256 feeAllocation =
            ((totalFeeCollected -
                feeLedger[_address].totalFeeCollected_LastClaim) * balance) /
                supply;
        feeLedger[_address].totalFeeCollected_LastClaim = totalFeeCollected;
        feeLedger[_address].totalSupply_LastClaim = currentSupply;
        feeLedger[_address].userBalance_LastClaim = currentBalance;
        feeBalance[_address] = feeBalance[_address] + feeAllocation;
        return feeAllocation;
    }

    function claimFee() public returns (uint256) {
        require(GFI.balanceOf(msg.sender) > 0, "User has no GFI");
        uint256 supply;
        uint256 balance;

        //Pick the greatest supply and the lowest user balance
        uint256 currentBalance = GFI.balanceOf(msg.sender);
        if (currentBalance > feeLedger[msg.sender].userBalance_LastClaim) {
            balance = feeLedger[msg.sender].userBalance_LastClaim;
        } else {
            balance = currentBalance;
        }

        uint256 currentSupply = GFI.totalSupply();
        if (currentSupply < feeLedger[msg.sender].totalSupply_LastClaim) {
            supply = feeLedger[msg.sender].totalSupply_LastClaim;
        } else {
            supply = currentSupply;
        }

        uint256 feeAllocation =
            ((totalFeeCollected -
                feeLedger[msg.sender].totalFeeCollected_LastClaim) * balance) /
                supply;
        feeLedger[msg.sender].totalFeeCollected_LastClaim = totalFeeCollected;
        feeLedger[msg.sender].totalSupply_LastClaim = currentSupply;
        feeLedger[msg.sender].userBalance_LastClaim = currentBalance;
        //Add any extra fees they need to collect
        feeAllocation = feeAllocation + feeBalance[msg.sender];
        feeBalance[msg.sender] = 0;
        require(WETH.transfer(msg.sender, feeAllocation),"Failed to delegate wETH to caller");
        return feeAllocation;
    }

    function delegateFee(address reciever) public returns (uint256) {
        require(GFI.balanceOf(msg.sender) > 0, "User has no GFI");
        uint256 supply;
        uint256 balance;

        //Pick the greatest supply and the lowest user balance
        uint256 currentBalance = GFI.balanceOf(msg.sender);
        if (currentBalance > feeLedger[msg.sender].userBalance_LastClaim) {
            balance = feeLedger[msg.sender].userBalance_LastClaim;
        } else {
            balance = currentBalance;
        }

        uint256 currentSupply = GFI.totalSupply();
        if (currentSupply < feeLedger[msg.sender].totalSupply_LastClaim) {
            supply = feeLedger[msg.sender].totalSupply_LastClaim;
        } else {
            supply = currentSupply;
        }

        uint256 feeAllocation =
            ((totalFeeCollected -
                feeLedger[msg.sender].totalFeeCollected_LastClaim) * balance) /
                supply;
        feeLedger[msg.sender].totalFeeCollected_LastClaim = totalFeeCollected;
        feeLedger[msg.sender].totalSupply_LastClaim = currentSupply;
        feeLedger[msg.sender].userBalance_LastClaim = currentBalance;
        //Add any extra fees they need to collect
        feeAllocation = feeAllocation + feeBalance[msg.sender];
        feeBalance[msg.sender] = 0;
        require(WETH.transfer(reciever, feeAllocation), "Failed to delegate wETH to reciever");
        return feeAllocation;
    }

    function withdrawFee() external {
        uint256 feeAllocation = feeBalance[msg.sender];
        feeBalance[msg.sender] = 0;
        require(WETH.transfer(msg.sender, feeAllocation), "Failed to delegate wETH to caller");
    }

    function govAuthTransfer(
        address caller,
        address to,
        uint256 amount
    ) external onlyToken returns (bool) {
        require(GFI.balanceOf(caller) >= amount, "GOVERNANCE: Amount exceedes balance!");
        updateFee(caller);
        _updateFeeReceiver(to, amount);
        return true;
    }

    function govAuthTransferFrom(
        address caller,
        address from,
        address to,
        uint256 amount
    ) external onlyToken returns (bool) {
        require(GFI.allowance(from, caller) >= amount, "GOVERNANCE: Amount exceedes allowance!");
        require(GFI.balanceOf(from) >= amount, "GOVERNANCE: Amount exceedes balance!");
        updateFee(from);
        _updateFeeReceiver(to, amount);
        return true;
    }

    function depositFee(uint256 amountWETH, uint256 amountWBTC) external {
        require(
            WETH.transferFrom(msg.sender, address(this), amountWETH),
            "Failed to transfer wETH into contract!"
        );
        require(
            WBTC.transferFrom(msg.sender, address(this), amountWBTC),
            "Failed to transfer wBTC into contract!"
        );
        totalFeeCollected = totalFeeCollected + amountWETH;
    }

    function claimBTC(uint256 amount) external {
        require(
            amount > 10**18,
            "Amount too small, must be greater than 1 GFI token!"
        );
        require(
            GFI.transferFrom(msg.sender, address(this), amount),
            "Failed to transfer GFI to governance contract!"
        );
        uint256 WBTCowed =
            (amount * WBTC.balanceOf(address(this))) / GFI.totalSupply();
        require(GFI.burn(amount), "Failed to burn GFI!");
        require(
            WBTC.transfer(msg.sender, WBTCowed),
            "Failed to transfer wBTC to caller!"
        );
    }
}