const { getChainId, ethers } = require("hardhat");

async function main() {
    const CONTRACT_OWNER = "0xeb678812778B68a48001B4A9A4A04c4924c33598";
    const chainId = await getChainId();

    [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log("");

    let GFI_ADDRESS = "0x874e178A2f3f3F9d34db862453Cd756E7eAb0381";
    let WETH_ADDRESS = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
    let WBTC_ADDRESS = "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6";
    let WMATIC_ADDRESS = "0x0000000000000000000000000000000000001010";
    let wETH;
    let wBTC;
    let GFI;
    
    if (chainId == 137){//Main net addresses
        GFI_ADDRESS = "0x874e178A2f3f3F9d34db862453Cd756E7eAb0381";
        WETH_ADDRESS = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
        WBTC_ADDRESS = "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6";
        WMATIC_ADDRESS = "0x0000000000000000000000000000000000001010";

        const WETH = await ethers.getContractFactory("MockWETH");
        wETH = await WETH.attach(WETH_ADDRESS);
        

        const WBTC = await ethers.getContractFactory("MockWBTC");
        wBTC = await WBTC.attach(WBTC_ADDRESS);
        

        const GravityToken = await ethers.getContractFactory("GravityToken");
        GFI = await GravityToken.attach(GFI_ADDRESS);
        
    }
    else{
        const WETH = await ethers.getContractFactory("MockWETH");
        wETH = await WETH.deploy();
        await wETH.deployed();
        console.log("wETH deployed to: ", wETH.address);

        const WBTC = await ethers.getContractFactory("MockWBTC");
        wBTC = await WBTC.deploy();
        await wBTC.deployed();
        console.log("wBTC deployed to: ", wBTC.address);

        const GravityToken = await ethers.getContractFactory("GravityToken");
        GFI = await GravityToken.deploy("Mock GFI", "mGFI");
        await GFI.deployed();
        console.log("mGFI deployed to: ", GFI.address);

        GFI_ADDRESS = GFI.address;
        WETH_ADDRESS = wETH.address;
        WBTC_ADDRESS = wBTC.address;

        let bal = await GFI.balanceOf(deployer.address);
        await GFI.transfer("0xeb678812778B68a48001B4A9A4A04c4924c33598", bal);
    }
    
    console.log("T-Minus... 10");
    const Governance = await ethers.getContractFactory("Governance");
    const governance = await upgrades.deployProxy(Governance, [GFI_ADDRESS, WETH_ADDRESS, WBTC_ADDRESS], { initializer: 'initialize' });
    

    console.log("T-Minus... 9");
    const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
    const uniswapV2Factory = await UniswapV2Factory.deploy(CONTRACT_OWNER, GFI_ADDRESS, WETH_ADDRESS, WBTC_ADDRESS);
    

    console.log("T-Minus... 8");
    const UniswapV2Router02 = await ethers.getContractFactory("UniswapV2Router02");
    const uniswapV2Router02 = await UniswapV2Router02.deploy(uniswapV2Factory.address, WMATIC_ADDRESS);
    

    console.log("T-Minus... 7");
    const FeeManager = await ethers.getContractFactory("FeeManager");
    const feeManager = await FeeManager.deploy(uniswapV2Factory.address);


    console.log("T-Minus... 6");
    const EarningsManager = await ethers.getContractFactory("EarningsManager");
    const earningsManager = await EarningsManager.deploy(uniswapV2Factory.address);

    let timeForPriceMaturity = 300;
    let timeForPriceExpiration = 600;
    console.log("T-Minus... 5");
    const PriceOracle = await ethers.getContractFactory("PriceOracle");
    const priceOracle = await PriceOracle.deploy(timeForPriceMaturity, timeForPriceExpiration);
    

    let favoredList = [WETH_ADDRESS, WBTC_ADDRESS, GFI_ADDRESS];
    let favoredLength = 3;
    console.log("T-Minus... 4");
    const PathOracle = await ethers.getContractFactory("PathOracle");
    const pathOracle = await PathOracle.deploy(favoredList, favoredLength);
    

    console.log("T-Minus... 3");
    const FarmFactory = await ethers.getContractFactory("FarmFactory");
    const farmFactory = await FarmFactory.deploy(GFI_ADDRESS, governance.address);
    
    
    console.log("T-Minus... 2");
    const CompounderFactory = await ethers.getContractFactory("CompounderFactory");
    const compounderFactory = await CompounderFactory.deploy(GFI_ADDRESS, farmFactory.address);
    

    console.log("T-Minus... 1");
    const Incinerator = await ethers.getContractFactory("Incinerator");
    const incinerator = await Incinerator.deploy(GFI_ADDRESS, WETH_ADDRESS, uniswapV2Factory.address, uniswapV2Router02.address, priceOracle.address);
    
    console.log();
    console.log("Lift Off! 🚀");
    console.log("Governance deployed to:        ", governance.address);
    console.log("UniswapV2Factory deployed to:  ", uniswapV2Factory.address);
    console.log("UniswapV2Router02 deployed to: ", uniswapV2Router02.address);
    console.log("FeeManager deployed to:        ", feeManager.address);
    console.log("EarningsManager deployed to:   ", earningsManager.address);
    console.log("PriceOracle deployed to:       ", priceOracle.address);
    console.log("PathOracle deployed to:        ", pathOracle.address);
    console.log("FarmFactory deployed to:       ", farmFactory.address);
    console.log("CompounderFactory deployed to: ", compounderFactory.address);
    console.log("Incinerator deployed to:       ", incinerator.address);

}
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });