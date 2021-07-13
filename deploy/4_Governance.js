module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
  }) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
  
    const gfiAddress = (await deployments.get("GravityToken")).address;
    const wethAddress = (await deployments.get("MockWETH")).address;
    const wbtcAddress = (await deployments.get("MockWBTC")).address;
    const startTime = 1624401900;
    const subPeriodLength = 900;
    const governance = await deploy('Governance', {
      from: deployer,
      gasLimit: 4000000,
      args: [gfiAddress, wethAddress, wbtcAddress],
      proxy: {
          owner: deployer,
          proxyContract: 'OpenZeppelinTransparentProxy',
          methodName: 'initialize',
      }
    });
  
    console.log("Governance deployed to: ", governance.address);
  };