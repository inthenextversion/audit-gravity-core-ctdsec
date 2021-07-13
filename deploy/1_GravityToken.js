module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
  }) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();
  
    const gravityToken = await deploy('GravityToken', {
      from: deployer,
      gasLimit: 4000000,
      args: ["Mock GFI", "mGFI"],
    });
  
    console.log("Gravity Token deployed to: ", gravityToken.address);
  };