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
    const govAddress = "0xE45442729892eAEC956bd074CD24dEd53670CDDF";
    const startTime = 1624401900;
    const subPeriodLength = 900;
    const vestingV2 = await deploy('VestingV2', {
      from: deployer,
      gasLimit: 4000000,
      args: [gfiAddress, wethAddress, govAddress, startTime, subPeriodLength],
    });
  
    console.log("VestingV2 deployed to: ", vestingV2.address);
  };