module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
  }) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
  
    const wbtc = await deploy('MockWBTC', {
      from: deployer,
      gasLimit: 4000000,
      args: [],
    });
  
    console.log("wBTC Token deployed to: ", wbtc.address);
  };