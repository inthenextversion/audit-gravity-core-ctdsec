// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IFarmFactory} from "../interfaces/IFarmFactory.sol";
import "../interfaces/IFarmV2.sol";
import "./Share.sol";
import "../interfaces/IShare.sol";
import "../interfaces/iGravityToken.sol";
import "../DeFi/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "../DeFi/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "../interfaces/IPriceOracle.sol";
import "../interfaces/ITierManager.sol";
import {UserInfo} from "../interfaces/IFarmV2.sol";
import {FarmInfo} from "../interfaces/IFarmV2.sol";
import {ShareInfo} from "../interfaces/ICompounderFactory.sol";//dont think this is needed


contract CompounderFactory is Ownable{
    mapping(address => ShareInfo) public farmAddressToShareInfo;
    iGravityToken GFI;
    IFarmFactory Factory;
    address public ShareTokenImplementation;
    mapping(address => address) public getShareToken;//input the farm address to get it's share token
    mapping(address => address) public getFarm;//input the share address to get it's farm
    address[] public allShareTokens;
    uint public vaultFee = 4; //Default 4% range 0 -> 5%
    uint public rewardBalance;
    mapping(address => uint) public lastHarvestDate;

    address public dustPan;
    address public feeManager;
    address public priceOracle;
    address public swapFactory;
    address public router;
    address public tierManager;
    address public gfi;
    uint public slippage = 0;
    uint public requiredTier;
    bool public checkTiers;
    mapping(address => bool) public whitelist;

    /**
    @dev emitted when a new compounder is created
    **/
    event CompounderCreated(address _farmAddress, uint requiredTier);

    /**
    * @dev emitted when owner changes the whitelist
    * @param _address the address that had its whitelist status changed
    * @param newBool the new state of the address
    **/
    event whiteListChanged(address _address, bool newBool);

    modifier compounderExists(address farmAddress){
        require(getShareToken[farmAddress] != address(0), "Compounder does not exist!");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "Caller is not in whitelist!");
        _;
    }

    constructor(address gfiAddress, address farmFactoryAddress, uint _requiredTier, address _tierManager) {
        GFI = iGravityToken(gfiAddress);
        Factory = IFarmFactory(farmFactoryAddress);
        Share ShareTokenRoot = new Share();
        ShareTokenImplementation = address(ShareTokenRoot);
        requiredTier = _requiredTier;
        tierManager = _tierManager;
    }

    function adjustWhitelist(address _address, bool _bool) external onlyOwner {
        whitelist[_address] = _bool;
        emit whiteListChanged(_address, _bool);
    }

    function changeVaultFee(uint newFee) external onlyOwner{
        require(newFee <= 5, 'Gravity Finance: FORBIDDEN');
        vaultFee = newFee;
    }

    function changeTierManager(address _tierManager) external onlyOwner{
        tierManager = _tierManager;
    }
    
    function changeCheckTiers(bool _bool) external onlyOwner{
        checkTiers = _bool;
    }

    function changeShareInfo(address farmAddress, uint _minHarvest, uint _maxCallerReward, uint _callerFeePercent) external onlyOwner compounderExists(farmAddress){
        require(_callerFeePercent <= 100, 'Gravity Finance: INVALID CALLER FEE PERCENT');

        farmAddressToShareInfo[farmAddress].minHarvest = _minHarvest;
        farmAddressToShareInfo[farmAddress].maxCallerReward = _maxCallerReward;
        farmAddressToShareInfo[farmAddress].callerFeePercent = _callerFeePercent;
    }

    function updateSharedVariables(address _dustPan, address _feeManager, address _priceOracle, address _swapFactory, address _router, uint _slippage) external onlyOwner{
        require(slippage <= 100, 'Gravity Finance: INVALID SLIPPAGE');
        dustPan = _dustPan;
        feeManager = _feeManager;
        priceOracle = _priceOracle;
        swapFactory = _swapFactory;
        router = _router;
        slippage = _slippage;
    }

    function createCompounder(address _farmAddress, address _depositToken, address _rewardToken, uint _maxCallerReward, uint _callerFee, uint _minHarvest, bool _lpFarm, address _lpA, address _lpB) external onlyWhitelist{
        
        require(getShareToken[_farmAddress] == address(0), "Share token already exists!");
        require(_callerFee <= 100, 'Gravity Finance: INVALID CALLER FEE PERCENT');

        //Create the clone proxy, and add it to the getFarm mappping, and allFarms array
        bytes32 salt = keccak256(abi.encodePacked(_farmAddress));
        address shareClone = Clones.cloneDeterministic(ShareTokenImplementation, salt);
        getShareToken[_farmAddress] = shareClone;
        getFarm[shareClone] = _farmAddress;
        allShareTokens.push(shareClone);
        farmAddressToShareInfo[_farmAddress] = ShareInfo({
            depositToken: _depositToken,
            rewardToken: _rewardToken,
            shareToken: shareClone,
            minHarvest: _minHarvest,
            maxCallerReward: _maxCallerReward,
            callerFeePercent: _callerFee,
            lpFarm: _lpFarm,
            lpA: _lpA,
            lpB: _lpB
        });
        IShare(shareClone).initialize();
        emit CompounderCreated(_farmAddress, requiredTier);
    }

    /**
    * @dev allows caller to deposit the depositToken corresponding to the given fid. 
    * In return caller is minted Shares for that farm
    **/
    function depositCompounding(address farmAddress, uint amountToDeposit) external compounderExists(farmAddress){
        if(checkTiers){
            require(ITierManager(tierManager).checkTier(msg.sender) >= requiredTier, "Caller does not hold high enough tier");
        }
        IERC20 DepositToken = IERC20(farmAddressToShareInfo[farmAddress].depositToken);
        IERC20 RewardToken = IERC20(farmAddressToShareInfo[farmAddress].rewardToken);//could also do Farm.farmInfo.rewardToken....
        IShare ShareToken = IShare(farmAddressToShareInfo[farmAddress].shareToken);
        IFarmV2 Farm = IFarmV2(farmAddress);

        //require deposit tokens are transferred into compounder
        require(DepositToken.transferFrom(msg.sender, address(this), amountToDeposit), 'Gravity Finance: TRANSFERFROM FAILED');

        //figure out the amount of shares owed to caller
        uint sharesOwed;
        if(Farm.userInfo(address(this)).amount != 0){
            sharesOwed = amountToDeposit * ShareToken.totalSupply()/Farm.userInfo(address(this)).amount;
        }
        else{
            sharesOwed = 10**18; //1 share distrbuted NOTE Share uses 18 decimals
        }

        //deposit tokens into farm, but keep track of how much reward token we get
        DepositToken.approve(address(Farm), amountToDeposit);
        uint rewardBalbefore = RewardToken.balanceOf(address(this));
        if (farmAddressToShareInfo[farmAddress].depositToken == farmAddressToShareInfo[farmAddress].rewardToken){//make sure to remove amount user just submitted
            rewardBalbefore = rewardBalbefore - amountToDeposit;
        }
        Farm.deposit(amountToDeposit);
        uint rewardToReinvest = RewardToken.balanceOf(address(this)) - rewardBalbefore;

        //mint caller their share tokens
        require(ShareToken.mint(msg.sender, sharesOwed), 'Gravity Finance: SHARE MINT FAILED');

        rewardBalance += rewardToReinvest;
    }

    /**
    * @dev allows caller to exchange farm share tokens for corresponding farms deposit token
    **/
    function withdrawCompounding(address farmAddress, uint amountToWithdraw) external compounderExists(farmAddress){
        IERC20 DepositToken = IERC20(farmAddressToShareInfo[farmAddress].depositToken);
        IERC20 RewardToken = IERC20(farmAddressToShareInfo[farmAddress].rewardToken);//could also do Farm.farmInfo.rewardToken....
        IShare ShareToken = IShare(farmAddressToShareInfo[farmAddress].shareToken);
        IFarmV2 Farm = IFarmV2(farmAddress);

        //figure out the amount of deposit tokens owed to caller
        uint depositTokensOwed = amountToWithdraw * Farm.userInfo(address(this)).amount/ShareToken.totalSupply();

        //require shares are burned
        require(ShareToken.burn(msg.sender, amountToWithdraw), 'Gravity Finance: SHARE BURN FAILED');

        //withdraw depositTokensOwed but keep track of rewards harvested
        uint rewardBalbefore = RewardToken.balanceOf(address(this));
        Farm.withdraw(depositTokensOwed);
        uint rewardToReinvest = RewardToken.balanceOf(address(this)) - rewardBalbefore;
        if (farmAddressToShareInfo[farmAddress].depositToken == farmAddressToShareInfo[farmAddress].rewardToken){//make sure to remove amount user just submitted to withdraw
            rewardToReinvest = rewardToReinvest - depositTokensOwed;
        }

        //Transfer depositToken to caller
        require(DepositToken.transfer(msg.sender, depositTokensOwed), 'Gravity Finance: TRANSFER FAILED');

        rewardBalance += rewardToReinvest;
    }

    /**
    * @dev allows caller to harvest compounding farms pending rewards, in exchange for a callers fee(paid in reward token)
    use rewardBalance and reinvest that
    * If reward token and deposit token are the same, then it just reinvests teh tokens.
    * If the deposit token is an LP token, then it swaps half the reward token for deposittokens
    **/
    function harvestCompounding(address farmAddress) external compounderExists(farmAddress) returns(uint timeTillValid) {

        //check if reward and deposit are the same, if they aren't then we need to use the price oracle
        if(farmAddressToShareInfo[farmAddress].depositToken != farmAddressToShareInfo[farmAddress].rewardToken){
            if(farmAddressToShareInfo[farmAddress].lpFarm){
                (,,timeTillValid) = IPriceOracle(priceOracle).getPrice(farmAddressToShareInfo[farmAddress].depositToken);
                address pairAddress = IUniswapV2Factory(swapFactory).getPair(farmAddressToShareInfo[farmAddress].lpA, farmAddressToShareInfo[farmAddress].rewardToken);
                (,,uint timeTillValidOther) = IPriceOracle(priceOracle).getPrice(pairAddress);
                if (timeTillValid < timeTillValidOther){
                    timeTillValid = timeTillValidOther;
                }
            }
            else{
                address pairAddress = IUniswapV2Factory(swapFactory).getPair(farmAddressToShareInfo[farmAddress].depositToken, farmAddressToShareInfo[farmAddress].rewardToken);
                (,,timeTillValid) = IPriceOracle(priceOracle).getPrice(pairAddress);
            }
        }

        //If timeTillValid is 0 or the reward and deposit token are the same, then proceed with the rest of the reinvest
        if(timeTillValid == 0){//Ensure swap price is valid
            IERC20 RewardToken = IERC20(farmAddressToShareInfo[farmAddress].rewardToken);//could also do Farm.farmInfo.rewardToken....
            uint rewardToReinvest;
            {
                IFarmV2 Farm = IFarmV2(farmAddress);

                //make sure pending reward is greater than min harvest
                require((Farm.pendingReward(address(this)) + rewardBalance) >= farmAddressToShareInfo[farmAddress].minHarvest, 'Gravity Finance: MIN HARVEST NOT MET');

                //harvest reward keeping track of rewards harvested
                uint rewardBalbefore = RewardToken.balanceOf(address(this));
                Farm.deposit(0);
                rewardToReinvest = RewardToken.balanceOf(address(this)) - rewardBalbefore;
                rewardToReinvest += rewardBalance;
            }
            uint reward = _reinvest(farmAddress, rewardToReinvest, true);
            rewardBalance = 0;

            lastHarvestDate[farmAddress] = block.timestamp;
            require(RewardToken.transfer(msg.sender, reward), 'Gravity Finance: TRANSFER FAILED');
        }
    }

    /**
    * @dev called at the end of harvestCompounding
    * to take any harvested rewards, convert them into the deposit token, and reinvest them
    * In order for single sided farms with different reward and deposit tokens to work, their needs to be
    * a swap pair with the reward and deposit tokens
    * In order for LP farms to work, there needs to be swap pair between reward, and lpA
    **/
    function _reinvest(address farmAddress, uint amountToReinvest, bool rewardCaller) internal returns(uint callerReward){
        IERC20 DepositToken = IERC20(farmAddressToShareInfo[farmAddress].depositToken);
        IERC20 RewardToken = IERC20(farmAddressToShareInfo[farmAddress].rewardToken);//could also do Farm.farmInfo.rewardToken....
        IFarmV2 Farm = IFarmV2(farmAddress);

        if(vaultFee > 0){//handle vault fee
            uint fee = vaultFee * amountToReinvest / 100;
            amountToReinvest = amountToReinvest - fee;
            if(farmAddressToShareInfo[farmAddress].rewardToken == address(GFI)){//burn it
                GFI.burn(fee);
            }
            else{//send it to fee manager
                RewardToken.transfer(feeManager, fee);
            }
        }
        //handle caller reward
        if(rewardCaller){
            callerReward = farmAddressToShareInfo[farmAddress].callerFeePercent * amountToReinvest / 100;
            if (callerReward > farmAddressToShareInfo[farmAddress].maxCallerReward){
                callerReward = farmAddressToShareInfo[farmAddress].maxCallerReward;
            }
            amountToReinvest = amountToReinvest - callerReward;
        } 

        //check if the deposit token and the reward token are not the same
        if (farmAddressToShareInfo[farmAddress].depositToken != farmAddressToShareInfo[farmAddress].rewardToken){
            address[] memory path = new address[](2);
            uint[] memory amounts = new uint[](2);

            if (farmAddressToShareInfo[farmAddress].lpFarm){//Dealing with an LP farm so swap half the reward for deposit and supply liqduity
                
                path[0] = farmAddressToShareInfo[farmAddress].rewardToken;
                path[1] = farmAddressToShareInfo[farmAddress].lpA;
                RewardToken.approve(router, amountToReinvest);
                (uint minAmount,) = IPriceOracle(priceOracle).calculateMinAmount(path[0], slippage, amountToReinvest, IUniswapV2Factory(swapFactory).getPair(path[0], path[1]));
                amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
                    amountToReinvest,
                    minAmount,
                    path,
                    address(this),
                    block.timestamp
                );

                path[0] = farmAddressToShareInfo[farmAddress].lpA;
                path[1] = farmAddressToShareInfo[farmAddress].lpB;
                IERC20(path[0]).approve(router, amounts[1]/2);
                (minAmount,) = IPriceOracle(priceOracle).calculateMinAmount(path[0], slippage, amounts[1] / 2, address(DepositToken));
                amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
                    amounts[1] / 2,
                    minAmount,
                    path,
                    address(this),
                    block.timestamp
                );
                
                IERC20(path[0]).approve(router, amounts[0]);
                IERC20(path[1]).approve(router, amounts[1]);
                //Don't need to use minAmounts here bc amounts array was set by using minAmounts to make the initial swap
                uint token0Var = (slippage * amounts[0]) / 100; 
                uint token1Var = (slippage * amounts[1]) / 100;
                (token0Var, token1Var,) = IUniswapV2Router02(router).addLiquidity(
                    path[0],
                    path[1],
                    amounts[0],
                    amounts[1],
                    token0Var,
                    token1Var,
                    address(this),
                    block.timestamp
                );
                
                amountToReinvest = DepositToken.balanceOf(address(this));//The amount of LP tokens we have

                //if((amounts[0] - token0Var) > 0){IERC20(path[0]).transfer(dustPan, (amounts[0] - token0Var));}
                //if((amounts[1] - token1Var) > 0){IERC20(path[1]).transfer(dustPan, (amounts[1] - token1Var));}

            }
            else{//need to swap all reward for deposit token
                address pairAddress = IUniswapV2Factory(swapFactory).getPair(farmAddressToShareInfo[farmAddress].depositToken, farmAddressToShareInfo[farmAddress].rewardToken);
                path[0] = farmAddressToShareInfo[farmAddress].rewardToken;
                path[1] = farmAddressToShareInfo[farmAddress].depositToken;
                RewardToken.approve(router, amountToReinvest);
                (uint minAmount,) = IPriceOracle(priceOracle).calculateMinAmount(farmAddressToShareInfo[farmAddress].rewardToken, slippage, amountToReinvest, pairAddress);
                amounts = IUniswapV2Router02(router).swapExactTokensForTokens(
                    amountToReinvest,
                    minAmount,
                    path,
                    address(this),
                    block.timestamp
                );
                amountToReinvest = amounts[1]; //What we got out of the swap
            }
        }
        DepositToken.approve(address(Farm), amountToReinvest);
        Farm.deposit(amountToReinvest);
    }
}