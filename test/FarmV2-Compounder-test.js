const { expect } = require("chai");
const { ethers, network, upgrades, getBlockNumber } = require("hardhat");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

let MockERC20;
let mockWETH;
let MockGFI;
let mockGFI;
let mockSUSHI;
let mockLINK;
let farmWBTCGFI;


//Test wallet addresses
let owner; // Test contract owner
let addr1; // Test user 1
let addr2; // Test user 2
let addr3; // Test user 3
let addr4; // Test user 4
let addr5;

let WETH;
let WBTC;
let GFI;
let USDC;
let wETHwBTC;
let wETHGFI;
let GFIwBTC;
let USDCwBTC;
let DAI;
let WMATIC;
let LINK;
let SUSHI;

before(async function () {
    [owner, addr1, addr2, addr3, addr4, addr5] = await ethers.getSigners();

    MockERC20 = await ethers.getContractFactory("MockToken");
    mockWETH = await MockERC20.deploy(addr1.address, addr2.address, addr3.address, addr4.address);
    await mockWETH.deployed();
    WETH = mockWETH.address;

    MockERC20 = await ethers.getContractFactory("MockToken");
    mockLINK = await MockERC20.deploy(addr1.address, addr2.address, addr3.address, addr4.address);
    await mockLINK.deployed();
    LINK = mockLINK.address;

    MockERC20 = await ethers.getContractFactory("MockToken");
    mockSUSHI = await MockERC20.deploy(addr1.address, addr2.address, addr3.address, addr4.address);
    await mockSUSHI.deployed();
    SUSHI = mockSUSHI.address;
    

    MockERC20 = await ethers.getContractFactory("MockToken");
    mockWBTC = await MockERC20.deploy(addr1.address, addr2.address, addr3.address, addr4.address);
    await mockWBTC.deployed();
    WBTC = mockWBTC.address;

    MockERC20 = await ethers.getContractFactory("MockToken");
    mockUSDC = await MockERC20.deploy(addr1.address, addr2.address, addr3.address, addr4.address);
    await mockUSDC.deployed();
    USDC = mockUSDC.address;

    MockERC20 = await ethers.getContractFactory("MockToken");
    mockDAI = await MockERC20.deploy(addr1.address, addr2.address, addr3.address, addr4.address);
    await mockDAI.deployed();
    DAI = mockDAI.address;

    MockGFI = await ethers.getContractFactory("GravityToken");
    mockGFI = await MockGFI.deploy("Mock Gravity Finance", "MGFI");
    await mockGFI.deployed();
    GFI = mockGFI.address;

    MockWMATIC = await ethers.getContractFactory("MockToken");
    mockWMATIC = await MockWMATIC.deploy(addr1.address, addr2.address, addr3.address, addr4.address);
    await mockWMATIC.deployed();
    WMATIC = mockWMATIC.address;

    Governance = await ethers.getContractFactory("Governance");
    governance = await upgrades.deployProxy(Governance, [mockGFI.address, mockWETH.address, mockWBTC.address], { initializer: 'initialize' });
    await governance.deployed();
    await mockGFI.setGovernanceAddress(governance.address);
    await mockGFI.changeGovernanceForwarding(true);
    
    PathOracle = await ethers.getContractFactory("PathOracle");
    pathOracle = await PathOracle.deploy([mockWETH.address, mockWBTC.address, mockGFI.address, mockUSDC.address, mockDAI.address], 5);
    await pathOracle.deployed();
    await pathOracle.alterPath(WETH, WBTC);
    await pathOracle.alterPath(WBTC, WETH);

    PriceOracle = await ethers.getContractFactory("PriceOracle");
    priceOracle = await PriceOracle.deploy(300, 600);
    await priceOracle.deployed();

    SwapFactory = await ethers.getContractFactory("UniswapV2Factory");
    swapFactory = await SwapFactory.deploy(owner.address, GFI, WETH, WBTC);
    await swapFactory.deployed();

    await pathOracle.setFactory(swapFactory.address);

    SwapRouter = await ethers.getContractFactory("UniswapV2Router02");
    swapRouter = await SwapRouter.deploy(swapFactory.address, mockWMATIC.address);
    await swapRouter.deployed();

    FeeManager = await ethers.getContractFactory("FeeManager");
    feeManager = await FeeManager.deploy(swapFactory.address);
    await feeManager.deployed;

    EarningsManager = await ethers.getContractFactory("EarningsManager");
    earningsManager = await EarningsManager.deploy(swapFactory.address);
    await earningsManager.deployed;

    FarmFactory = await ethers.getContractFactory("FarmFactory");
    farmFactory = await FarmFactory.deploy(GFI, governance.address);
    await farmFactory.deployed;

    CompounderFactory = await ethers.getContractFactory("CompounderFactory");
    compounderFactory = await CompounderFactory.deploy(GFI, farmFactory.address, 0, farmFactory.address);
    await compounderFactory.deployed;

    Incinerator = await ethers.getContractFactory("Incinerator");
    incinerator = await Incinerator.deploy(GFI, WETH, swapFactory.address, swapRouter.address, priceOracle.address);
    await incinerator.deployed;

    await swapFactory.setRouter(swapRouter.address);

    await swapFactory.setRouter(swapRouter.address);
    await swapFactory.setGovernor(governance.address);
    await swapFactory.setPathOracle(pathOracle.address);
    await swapFactory.setPriceOracle(priceOracle.address);
    await swapFactory.setEarningsManager(earningsManager.address);
    await swapFactory.setFeeManager(feeManager.address);
    await swapFactory.setDustPan(addr5.address);
    await swapFactory.setPaused(false);
    await swapFactory.setSlippage(95);

    await feeManager.adjustWhitelist(owner.address, true);
    await earningsManager.adjustWhitelist(owner.address, true);

    //Create swap pairs
    //create wETH/wBTC swap pair
    let pairAddress;
    await mockWETH.connect(addr1).approve(swapRouter.address, "5000000000000000000000");
    await mockWBTC.connect(addr1).approve(swapRouter.address, "1000000000000000000000");
    await swapRouter.connect(addr1).addLiquidity(mockWETH.address, mockWBTC.address, "5000000000000000000000", "1000000000000000000000", "4900000000000000000000", "9900000000000000000000", addr1.address, 1654341846);
    wETHwBTC = await swapFactory.getPair(mockWETH.address, mockWBTC.address);
    console.log("Created wETH/wBTC at: ", pairAddress);

    //Create wBTC USDC pair
    await mockUSDC.connect(addr1).approve(swapRouter.address, "1000000000000000000000");
    await mockWBTC.connect(addr1).approve(swapRouter.address, "100000000000000000000");
    await swapRouter.connect(addr1).addLiquidity(mockUSDC.address, mockWBTC.address, "1000000000000000000000", "100000000000000000000", "990000000000000000000", "99000000000000000000", addr1.address, 1654341846);
    USDCwBTC = await swapFactory.getPair(mockUSDC.address, mockWBTC.address);
    console.log("Created USDC/wBTC at: ", pairAddress);

    //Create wBTC GFI pair
    await mockGFI.transfer(addr1.address, "5000000000000000000000000");
    await mockGFI.connect(addr1).approve(swapRouter.address, "5000000000000000000000000");
    await mockWBTC.connect(addr1).approve(swapRouter.address, "1000000000000000000000");
    await swapRouter.connect(addr1).addLiquidity(mockGFI.address, mockWBTC.address, "5000000000000000000000000", "1000000000000000000000", "4900000000000000000000000", "990000000000000000000", addr1.address, 1654341846);
    GFIwBTC = await swapFactory.getPair(mockGFI.address, mockWBTC.address);
    console.log("Created  GFI/wBTC at: ", pairAddress);

    //Create wETH GFI pair
    await mockGFI.transfer(addr1.address, "10000000000000000000000000");
    await mockWETH.connect(addr1).approve(swapRouter.address, "1000000000000000000000");
    await mockGFI.connect(addr1).approve(swapRouter.address, "10000000000000000000000000");
    await swapRouter.connect(addr1).addLiquidity(mockWETH.address, mockGFI.address, "1000000000000000000000", "10000000000000000000000000", "990000000000000000000", "9900000000000000000000000", addr1.address, 1654341846);
    wETHGFI = await swapFactory.getPair(mockWETH.address, mockGFI.address);
    console.log("Created wETH/GFI at: ", pairAddress);

    await farmFactory.setFeeManager(feeManager.address);
    await farmFactory.setIncinerator(incinerator.address);
    await compounderFactory.updateSharedVariables(addr5.address, feeManager.address, priceOracle.address, swapFactory.address, swapRouter.address, 95);
    await farmFactory.setHarvestFee(5);

});

describe("Farm Factory functional test", function () {
    it("Create a GFI -> GFI farm", async function () {
        //Allow addr1 to create a GFI-GFI farm with 4,500 GFI as a reward, with no bonus
        await network.provider.send("evm_mine");
        await farmFactory.approveOrRevokeFarm(true, addr1.address, GFI, GFI, "4500000000000000000000", "100000000000000000000", 55, 200, 50, 1);

        await mockGFI.transfer(addr1.address, "9000000000000000000000");
        await mockGFI.connect(addr1).approve(farmFactory.address, "4500000000000000000000");
        await farmFactory.connect(addr1).createFarm(GFI, GFI, "4500000000000000000000", "100000000000000000000", 55, 200, 50, 1);
        farmAddress = await farmFactory.getFarm(GFI, GFI);
        let Farm = await ethers.getContractFactory("FarmV2");
        let farm = await Farm.attach(farmAddress);
        await mockGFI.connect(addr1).approve(farmAddress, "1000000000000000000000");
        await farm.connect(addr1).deposit("1000000000000000000000");
        let reward;
        for(let i = 0; i < 145; i++){
            await network.provider.send("evm_mine");
        }
        reward = Number(await farm.pendingReward(addr1.address)) / 10**18;
        expect(reward).to.be.above(2500);
        await expect(farm.connect(addr2).deposit("0")).to.be.reverted;//should revert since farming endBlock has passed
        //await farmFactory.adjustWhitelist(addr1.address, true);//only used to check if the whitelist logic works
        let balBefore = await mockGFI.totalSupply();
        await farm.connect(addr1).withdraw("1000000000000000000000");
        let balAfter = await mockGFI.totalSupply();
        console.log("GFI Burned: ", (balBefore - balAfter)/10**18);
    });

    it("Create a GFI/wBTC -> GFI farm", async function () {
        pairAddress = await swapFactory.getPair(mockGFI.address, mockWBTC.address);
        Pair = await ethers.getContractFactory("UniswapV2Pair");
        pair = await Pair.attach(pairAddress);
        let lpBal = await pair.balanceOf(addr1.address);
        console.log("lpBal: ", Number(lpBal)/10**18);

        //Allow addr1 to create a GFI-GFI farm with 4,500 GFI as a reward, with no bonus
        await network.provider.send("evm_mine");
        await farmFactory.approveOrRevokeFarm(true, addr1.address, pairAddress, GFI, "14500000000000000000000", "100000000000000000000", 210, 345, 50, 1);


        await mockGFI.transfer(addr1.address, "14500000000000000000000");
        await mockGFI.connect(addr1).approve(farmFactory.address, "14500000000000000000000");
        await farmFactory.connect(addr1).createFarm(pairAddress, GFI, "14500000000000000000000", "100000000000000000000", 210, 345, 50, 1);
        farmAddress = await farmFactory.getFarm(pairAddress, GFI);
        let Farm = await ethers.getContractFactory("FarmV2");
        let farm = await Farm.attach(farmAddress);
        await pair.connect(addr1).approve(farmAddress, lpBal);
        await network.provider.send("evm_mine");
        await farm.connect(addr1).deposit(lpBal);
        let reward;
        for(let i = 0; i < 145; i++){
            reward = Number(await farm.pendingReward(addr1.address)) / 10**18;
            //console.log("Pending Reward: ", reward);
            await network.provider.send("evm_mine");
        }
        await farmFactory.setHarvestFee(5);
        console.log("Pending Reward: ", reward);
        reward = Number(await farm.pendingReward(addr1.address)) / 10**18;
        let balBefore = await mockGFI.balanceOf(addr1.address);
        await farm.connect(addr1).withdraw(lpBal);
        let balAfter = await mockGFI.balanceOf(addr1.address);
        console.log("Harvested Rewards: ", (balAfter - balBefore)/10**18);
    });
    it("Create a USDC -> USDC farm and compounder", async function () {
        await network.provider.send("evm_mine");
        await farmFactory.approveOrRevokeFarm(true, addr1.address, USDC, USDC, "4500000000000000000000", "100000000000000000000", 360, 500, 50, 1);

        await mockUSDC.connect(addr1).approve(farmFactory.address, "4500000000000000000000");
        await farmFactory.connect(addr1).createFarm(USDC, USDC, "4500000000000000000000", "100000000000000000000", 360, 500, 50, 1);

        await compounderFactory.createCompounder(USDC, USDC, "10000000000000000000", 1, "10000000000000000000", false, USDC, USDC); //GFIs at the end don't matter since lpFarm is false
        let shareAddress = await compounderFactory.getShareToken(USDC, USDC);
        const Share = await ethers.getContractFactory("Share");
        const share = await Share.attach(shareAddress);

        let farmAddress = await farmFactory.getFarm(USDC, USDC);
        let Farm = await ethers.getContractFactory("FarmV2");
        let farm = await Farm.attach(farmAddress);
        await mockUSDC.connect(addr1).approve(farmAddress, "1000000000000000000000");
        await farm.connect(addr1).deposit("1000000000000000000000");

        let fid = await farmFactory.getFarmIndex(USDC, USDC);
        console.log("Farm ID: ", Number(fid));
        await mockUSDC.connect(addr2).approve(compounderFactory.address, "1000000000000000000000");
        await compounderFactory.connect(addr2).depositCompounding(fid, "1000000000000000000000");

        let reward;
        reward = (await farm.pendingReward(addr1.address)).toString();
        console.log("Pending Reward: ", reward);
        for(let i = 0; i < 145; i++){
            await network.provider.send("evm_mine");
            reward = Number(await farm.pendingReward(addr1.address)) / 10**18;
            if(i%10 == 0 && i < 100){
                await compounderFactory.connect(addr3).harvestCompounding(fid);
            }
            //console.log("Pending Reward: ", reward);
        }

        let balBefore = await mockUSDC.balanceOf(feeManager.address);
        console.log("Fee Manager USDC balance from reinvesting: ", Number(balBefore)/10**18);
        await farm.connect(addr1).withdraw("1000000000000000000000");
        let balAfter = await mockUSDC.balanceOf(feeManager.address);
        console.log("Fee Manager USDC: ", (balAfter - balBefore)/10**18);
        console.log("Fee Manager USDC balance total: ", Number(balAfter)/10**18);
    });

    it("Create a wETH/wBTC -> GFI farm and compounder", async function () {
        console.log("Block Number: ", Number(await network.provider.send("eth_blockNumber")));
        await farmFactory.approveOrRevokeFarm(true, addr1.address, wETHwBTC, GFI, "1000000000000000000000000", "100000000000000000000", 520, 1000, 50, 1);

        let Pair = await ethers.getContractFactory("UniswapV2Pair");
        let pair = await Pair.attach(wETHwBTC);

        await mockGFI.transfer(addr1.address, "1000000000000000000000000");
        await mockGFI.connect(addr1).approve(farmFactory.address, "1000000000000000000000000");
        await farmFactory.connect(addr1).createFarm(wETHwBTC, GFI, "1000000000000000000000000", "100000000000000000000", 520, 1000, 50, 1);
        farmAddress = await farmFactory.getFarm(wETHwBTC, GFI);
        let Farm = await ethers.getContractFactory("FarmV2");
        let farm = await Farm.attach(farmAddress);
        let lpBal = (await pair.balanceOf(addr1.address)).toString();

        //create compounder for wETH/wBTC -> GFI farm
        await compounderFactory.createCompounder(wETHwBTC, GFI, "10000000000000000000", 1, "10000000000000000000", true, WBTC, WETH);

        let fid = await farmFactory.getFarmIndex(wETHwBTC, GFI);
        await pair.connect(addr1).approve(compounderFactory.address, "100000000000000000000");
        await pair.connect(addr2).approve(farmAddress, "100000000000000000000");
        await pair.connect(addr1).transfer(addr2.address, "100000000000000000000");

        await network.provider.send("evm_mine");
        await network.provider.send("evm_mine");
        await compounderFactory.connect(addr1).depositCompounding(fid, "100000000000000000000");
        await farm.connect(addr2).deposit("100000000000000000000");

        await priceOracle.getPrice(wETHwBTC);
        await priceOracle.getPrice(GFIwBTC);

        console.log("Advance time by 300 seconds");
        await network.provider.send("evm_increaseTime", [300]);
        await network.provider.send("evm_mine");
        await compounderFactory.harvestCompounding(fid);
        let addr1_reward;
        let addr2_reward;
        for(let i = 0; i < 150; i++){
            await priceOracle.getPrice(wETHwBTC);
            await priceOracle.getPrice(GFIwBTC);
            if(i%10 == 0){
                await compounderFactory.connect(addr3).harvestCompounding(fid);
                //console.log("Callers GFI Balance: ", Number(await mockGFI.balanceOf(addr3.address)) /10**18);
                //console.log("Compounders LP Invested: ", (Number(await pair.balanceOf(farm.address))/10**18) - 100);
            }
            addr1_reward = Number(await farm.pendingReward(compounderFactory.address)) / 10**18;
            addr2_reward = Number(await farm.pendingReward(addr2.address)) / 10**18;
            //console.log("Block Number: ", Number(await network.provider.send("eth_blockNumber")), " Pending Reward Compounder: ", addr1_reward, " Pending Reward addr2: ", addr2_reward);
        }

        let shareAddress = await compounderFactory.getShareToken(wETHwBTC, GFI);
        let Share = await ethers.getContractFactory("Share");
        let share = await Share.attach(shareAddress);
        let shares = await share.balanceOf(addr1.address);
        await share.approve(compounderFactory.address, shares);
        let balBefore = await pair.balanceOf(addr1.address);
        await compounderFactory.connect(addr1).withdrawCompounding(fid, shares);
        let balAfter = await pair.balanceOf(addr1.address);
        console.log("Address 1 LP Bal: ", Number(balAfter - balBefore)/10**18);
        expect(Number(balAfter - balBefore)/10**18).to.be.above(103);
    });

    //TEST compounder for a wBTC -> GFI farm
    it("Create a wBTC -> GFI farm and compounder", async function () {
        console.log("Block Number: ", Number(await network.provider.send("eth_blockNumber")));
        await farmFactory.approveOrRevokeFarm(true, addr1.address, WBTC, GFI, "100000000000000000000000000", "100000000000000000000", 840, 1020, 50, 1);

        await mockGFI.transfer(addr1.address, "100000000000000000000000000");
        await mockGFI.connect(addr1).approve(farmFactory.address, "100000000000000000000000000");
        await farmFactory.connect(addr1).createFarm(WBTC, GFI, "100000000000000000000000000", "100000000000000000000", 840, 1020, 50, 1);
        farmAddress = await farmFactory.getFarm(WBTC, GFI);
        let Farm = await ethers.getContractFactory("FarmV2");
        farmWBTCGFI = await Farm.attach(farmAddress);
        let lpBal = (await pair.balanceOf(addr1.address)).toString();

        //create compounder for wETH/WBTC -> GFI farm
        await compounderFactory.createCompounder(WBTC, GFI, "10000000000000000000", 1, "10000000000000000000", false, WBTC, WETH);

        let fid = await farmFactory.getFarmIndex(WBTC, GFI);
        await mockWBTC.connect(addr3).approve(compounderFactory.address, "100000000000000000000");
        await mockWBTC.connect(addr2).approve(farmAddress, "100000000000000000000");

        await compounderFactory.connect(addr3).depositCompounding(fid, "100000000000000000000");
        await farmWBTCGFI.connect(addr2).deposit("100000000000000000000");
        let pairAddress = await swapFactory.getPair(WBTC, GFI);
        await priceOracle.getPrice(pairAddress);

        console.log("Advance time by 300 seconds");
        await network.provider.send("evm_increaseTime", [300]);
        await network.provider.send("evm_mine");
        await compounderFactory.harvestCompounding(fid);
        let addr3_reward;
        let addr2_reward;
        for(let i = 0; i < 150; i++){
            await priceOracle.getPrice(pairAddress);
            if(i%10 == 0 && Number(await network.provider.send("eth_blockNumber")) < 1020){
                await compounderFactory.connect(addr3).harvestCompounding(fid);
                //console.log("Callers GFI Balance: ", Number(await mockGFI.balanceOf(addr3.address)) /10**18);
                //console.log("Compounders wBTC Invested: ", (Number(await mockWBTC.balanceOf(farm.address))/10**18) - 100);
            }
            addr3_reward = Number(await farmWBTCGFI.pendingReward(compounderFactory.address)) / 10**18;
            addr2_reward = Number(await farmWBTCGFI.pendingReward(addr2.address)) / 10**18;
            //console.log("Block Number: ", Number(await network.provider.send("eth_blockNumber")), " Pending Reward Compounder: ", addr3_reward, " Pending Reward addr2: ", addr2_reward);
        }

        let shareAddress = await compounderFactory.getShareToken(WBTC, GFI);
        let Share = await ethers.getContractFactory("Share");
        let share = await Share.attach(shareAddress);
        let shares = await share.balanceOf(addr3.address);
        await share.approve(compounderFactory.address, shares);
        let balBefore = await mockWBTC.balanceOf(addr3.address);
        await compounderFactory.connect(addr3).withdrawCompounding(fid, shares);
        let balAfter = await mockWBTC.balanceOf(addr3.address);
        console.log("Address 1 LP Bal: ", Number(balAfter - balBefore)/10**18);
        expect(Number(balAfter - balBefore)/10**18).to.be.above(101.0);
    });

    //TODO Create new GFI -> GFI farm and test a compounder for it
    it("Create a GFI -> GFI farm and compounder", async function () {
        console.log("Block Number: ", Number(await network.provider.send("eth_blockNumber")));
        await farmFactory.approveOrRevokeFarm(true, addr1.address, GFI, GFI, "1000000000000000000000000", "1000000000000000000000", 1015, 1320, 0, 1);

        await mockGFI.transfer(addr1.address, "1000000000000000000000000");
        await mockGFI.connect(addr1).approve(farmFactory.address, "1000000000000000000000000");
        await farmFactory.connect(addr1).createFarm(GFI, GFI, "1000000000000000000000000", "1000000000000000000000", 1015, 1320, 0, 1);
        farmAddress = await farmFactory.getFarm(GFI, GFI);
        let Farm = await ethers.getContractFactory("FarmV2");
        let farm = await Farm.attach(farmAddress);

        //create compounder for GFI -> GFI farm
        await compounderFactory.createCompounder(GFI, GFI, "10000000000000000000", 1, "10000000000000000000", false, WBTC, WETH);

        let fid = await farmFactory.getFarmIndex(GFI, GFI);
        await mockGFI.transfer(addr3.address, "10000000000000000000000");
        await mockGFI.transfer(addr2.address, "10000000000000000000000");
        await mockGFI.connect(addr3).approve(compounderFactory.address, "10000000000000000000000");
        await mockGFI.connect(addr2).approve(farmAddress, "10000000000000000000000");
        
        
        await compounderFactory.connect(addr3).depositCompounding(fid, "10000000000000000000000");
        await farm.connect(addr2).deposit("10000000000000000000000");
        
        console.log("Advance time by 300 seconds");
        await network.provider.send("evm_increaseTime", [300]);
        await network.provider.send("evm_mine");
        let GFItotalSupplyBefore = await mockGFI.totalSupply();
        let addr3_reward;
        let addr2_reward;
        for(let i = 0; i < 150; i++){
            if(i%10 == 0){
                await compounderFactory.connect(addr3).harvestCompounding(fid);
                //console.log("Callers GFI Balance: ", Number(await mockGFI.balanceOf(addr3.address)) /10**18);
                //console.log("Compounders GFI Invested: ", (Number(await mockGFI.balanceOf(farm.address))/10**18) - 100);
            }
            addr3_reward = Number(await farm.pendingReward(compounderFactory.address)) / 10**18;
            addr2_reward = Number(await farm.pendingReward(addr2.address)) / 10**18;
            //console.log("Block Number: ", Number(await network.provider.send("eth_blockNumber")), " Pending Reward Compounder: ", addr3_reward, " Pending Reward addr2: ", addr2_reward);
            await network.provider.send("evm_mine");//Think this is needed bc pendingRewards is a view function
        }
        let GFItotalSupplyAfter = await mockGFI.totalSupply();
        console.log("GFI Burned from reinvesting: ", Number(GFItotalSupplyBefore - GFItotalSupplyAfter)/10**18);
        let shareAddress = await compounderFactory.getShareToken(GFI, GFI);
        let Share = await ethers.getContractFactory("Share");
        let share = await Share.attach(shareAddress);
        let shares = await share.balanceOf(addr3.address);
        await share.approve(compounderFactory.address, shares);
        let balBefore = await mockGFI.balanceOf(addr3.address);
        await compounderFactory.connect(addr3).withdrawCompounding(fid, shares);
        let balAfter = await mockGFI.balanceOf(addr3.address);
        let balBefore1 = await mockGFI.balanceOf(addr2.address);
        await farm.connect(addr2).withdraw("10000000000000000000000");
        let balAfter1 = await mockGFI.balanceOf(addr2.address);
        console.log("Address 3 GFI Interest: ", Number(balAfter - balBefore)/10**18, "Address 2 GFI Interest: ", Number(balAfter1 - balBefore1)/10**18);
        //expect(Number(balAfter - balBefore)/10**18).to.be.above(Number(balAfter1 - balBefore1)/10**18)
        
    });

    it("Make sure farm earnings go to Incinerator and are used to buy and burn GFI", async function () {
        //deposit fee into governance
        await mockWETH.connect(addr4).approve(governance.address, "10000000000000000000");
        await mockWBTC.connect(addr4).approve(governance.address, "2000000000000000000");
        await governance.connect(addr4).depositFee("10000000000000000000", "2000000000000000000");

        console.log("Incinerator wETH Bal: ", (await mockWETH.balanceOf(incinerator.address)).toString());
        await farmWBTCGFI.sendEarningsToIncinerator();
        console.log("Incinerator wETH Bal: ", (await mockWETH.balanceOf(incinerator.address)).toString());

        let balBefore = Number(await mockGFI.totalSupply());
        await incinerator.convertEarningsToGFIandBurn();
        await network.provider.send("evm_increaseTime", [300]);
        await network.provider.send("evm_mine");
        await incinerator.convertEarningsToGFIandBurn();
        let balAfter = Number(await mockGFI.totalSupply());
        console.log("GFI Burned: ", (balBefore - balAfter)/10**18);

        console.log("GFI Total Supply: ", Number(await mockGFI.totalSupply())/10**18);



    });

});