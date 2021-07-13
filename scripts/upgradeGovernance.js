const { upgrades } = require("hardhat");

async function main() {

    [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log("");
    let proxyAddress = "0x3dc54058766ce3fc428a2EBdD91dbF45B2b8F90C";

    const GovernanceV1 = await ethers.getContractFactory("GovernanceV1");
    console.log("Preparing upgrade...");
    const governanceV1Address = await upgrades.prepareUpgrade(proxyAddress, GovernanceV1);
    console.log("Governance V1 at: ", governanceV1Address);
    const governanceV1 = await upgrades.upgradeProxy(proxyAddress, GovernanceV1);
    console.log("Upgrade Successful!");

  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });