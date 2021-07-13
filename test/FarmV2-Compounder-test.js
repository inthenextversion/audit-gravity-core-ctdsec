const { expect } = require("chai");
const { ethers, network, upgrades, getBlockNumber } = require("hardhat");
const { isCallTrace } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

let MockERC20;
let mockWETH;
let MockGFI;
let mockGFI;
let mockSUSHI;
let mockLINK;


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
    compounderFactory = await CompounderFactory.deploy(GFI, farmFactory.address);
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
    let pairAddress;
    await mockWETH.connect(addr1).approve(swapRouter.address, "1000000000000000000000");
    await mockWBTC.connect(addr1).approve(swapRouter.address, "100000000000000000000");
    await swapRouter.connect(addr1).addLiquidity(mockWETH.address, mockWBTC.address, "1000000000000000000000", "100000000000000000000", "990000000000000000000", "99000000000000000000", addr1.address, 1654341846);
    pairAddress = await swapFactory.getPair(mockWETH.address, mockWBTC.address);
    console.log("Created wETH/wBTC at: ", pairAddress);

    //Create wBTC USDC pair
    await mockUSDC.connect(addr1).approve(swapRouter.address, "1000000000000000000000");
    await mockWBTC.connect(addr1).approve(swapRouter.address, "100000000000000000000");
    await swapRouter.connect(addr1).addLiquidity(mockUSDC.address, mockWBTC.address, "1000000000000000000000", "100000000000000000000", "990000000000000000000", "99000000000000000000", addr1.address, 1654341846);
    pairAddress = await swapFactory.getPair(mockUSDC.address, mockWBTC.address);
    console.log("Created USDC/wBTC at: ", pairAddress);

    //Create wBTC GFI pair
    await mockGFI.transfer(addr1.address, "1000000000000000000000");
    await mockGFI.connect(addr1).approve(swapRouter.address, "1000000000000000000000");
    await mockWBTC.connect(addr1).approve(swapRouter.address, "100000000000000000000");
    await swapRouter.connect(addr1).addLiquidity(mockGFI.address, mockWBTC.address, "1000000000000000000000", "100000000000000000000", "990000000000000000000", "99000000000000000000", addr1.address, 1654341846);
    pairAddress = await swapFactory.getPair(mockGFI.address, mockWBTC.address);
    console.log("Created  GFI/wBTC at: ", pairAddress);

    await farmFactory.setFeeManager(feeManager.address);
    await farmFactory.setIncinerator(incinerator.address);
    await compounderFactory.updateSharedVariables(addr5.address, feeManager.address, priceOracle.address, swapFactory.address, swapRouter.address, 95);

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
        expect(reward).to.be.equal(2600);
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
        await farm.connect(addr1).deposit(0);
        let balAfter = await mockGFI.balanceOf(addr1.address);
        console.log("Harvested Rewards: ", (balAfter - balBefore)/10**18);
    });

});