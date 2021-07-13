async function main() {
    [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log("");
    
    const gfiAddress = "0x00EB5f921b8c2aF6E9D7A5fF6178E2971134D6D1";
    const wethAddress = "0xa887a37fE87F10702dcA4d0820bD1D5854646830";
    const wbtcAddress = "0x9FC9d2a7A43fd4c758433a2A41d130e8AEa2B2E0";

    const Governance = await ethers.getContractFactory("Governance");
    const governance = await upgrades.deployProxy(Governance, [gfiAddress, wethAddress, wbtcAddress], { initializer: 'initialize' });
    console.log("Governance deployed to: ", governance.address);

  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });