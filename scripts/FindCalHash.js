const { ethers } = require("ethers");

async function main() {
    const CONTRACT_OWNER = "0xeb678812778B68a48001B4A9A4A04c4924c33598";
    const WETH_ADDRESS = "0x3C68CE8504087f89c640D02d133646d98e64ddd9";
    [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log("");
    /**
     * @dev Deploy the Gravity Token Contract
     */
    const CalHash = await ethers.getContractFactory("CalHash");
    const calhash = await CalHash.deploy();
    await calhash.deployed();

    console.log(await calhash.getInitHash());

  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });