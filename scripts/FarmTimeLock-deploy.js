const { getChainId, ethers } = require("hardhat");

async function main() {
    const CONTRACT_OWNER = "0xeb678812778B68a48001B4A9A4A04c4924c33598";
    const chainId = await getChainId();

    [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log("");

    let FarmTimeLock;
    let farmTimeLock;
    let lockLength;
    let graceLength;
    let newOwner;
    
    if (chainId == 137){//Main net addresses
        lockLength = 604800;// 1 week
        graceLength = 86400; // 1 day
        newOwner = CONTRACT_OWNER;
    }
    else{
        lockLength = 300; //5 min
        graceLength = 300; //5 min
        newOwner = "0xa5E5860B34ac0C55884F2D0E9576d545e1c7Dfd4";
    }

    FarmTimeLock = await ethers.getContractFactory("FarmTimeLock");
    farmTimeLock = await FarmTimeLock.deploy(lockLength, graceLength);
    await farmTimeLock.deployed();
    console.log("Deployed Farm Timelock to: ", farmTimeLock.address);
    console.log("Transferring ownership of timelock to: ", newOwner);
    await farmTimeLock.transferOwnership(newOwner);
    console.log("Success!");

}
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });