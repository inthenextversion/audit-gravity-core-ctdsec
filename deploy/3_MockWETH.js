module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
  }) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
  
    const weth = await deploy('MockWETH', {
      from: deployer,
      gasLimit: 4000000,
      args: [],
    });
  
    console.log("wETH Token deployed to: ", weth.address);
  };