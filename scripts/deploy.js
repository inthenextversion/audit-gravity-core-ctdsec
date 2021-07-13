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
    let wETH;
    let wBTC;
    let GFI;
    let startTime;
    let subPeriodLength;
    
    if (chainId == 137){//Main net addresses
        GFI_ADDRESS = "0x874e178A2f3f3F9d34db862453Cd756E7eAb0381";
        WETH_ADDRESS = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
        WBTC_ADDRESS = "0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6";

        const WETH = await ethers.getContractFactory("MockWETH");
        wETH = await WETH.attach(WETH_ADDRESS);
        

        const WBTC = await ethers.getContractFactory("MockWBTC");
        wBTC = await WBTC.attach(WBTC_ADDRESS);
        

        const GravityToken = await ethers.getContractFactory("GravityToken");
        GFI = await GravityToken.attach(GFI_ADDRESS);
        
        startTime = 1622530800;
        subPeriodLength = 2592000;
        
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

        startTime = 1625016000; //June 23rd @10AM PST
        subPeriodLength = 300; //5 min
    }

    const Governance = await ethers.getContractFactory("Governance");
    const governance = await upgrades.deployProxy(Governance, [GFI_ADDRESS, WETH_ADDRESS, WBTC_ADDRESS], { initializer: 'initialize' });
    console.log("Governance deployed to: ", governance.address);

    //REMOVE THIS LINE FOR MAINNET DEPLOYMENT IT WILL FAIL A REQUIRE
    await GFI.setGovernanceAddress(governance.address);
    await GFI.changeGovernanceForwarding(true);
    await GFI.transferOwnership(CONTRACT_OWNER);
    //--------------------------------------------------------------

    const VestingV2 = await ethers.getContractFactory("VestingV2");
    const vestingV2 = await VestingV2.deploy(GFI_ADDRESS, WETH_ADDRESS, governance.address, startTime, subPeriodLength);
    await vestingV2.deployed();
    console.log("VestingV2 deployed to: ", vestingV2.address);

    await vestingV2.transferOwnership("0xeb678812778B68a48001B4A9A4A04c4924c33598");

}
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });