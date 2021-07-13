async function main() {
    [deployer] = await ethers.getSigners();
    const chainId = await getChainId();
    console.log("Deployer address:", deployer.address);
    console.log("");
    
    let gfiAddress = "0x874e178A2f3f3F9d34db862453Cd756E7eAb0381";
    let vestingAddress = "0x9FC9d2a7A43fd4c758433a2A41d130e8AEa2B2E0";

    let users = [
      ["0x1cfb034713e5ac0d736dbf9e9249461a2ea78123",1600000],
      ["0xC6B9E3fe34cC81D2977810FB98e96E6113Edc948",160000],
      ["0xe67B5f38827a194EB09853911337c1c13D7604e7",160000],
      ["0xBBdE8045DD3dDce476caEC0e8A60Ae0E1b700fF1",145063],
      ["0x6eDF519434Fe4C29F89fb9733c51a211FE26565f",160000],
      ["0x20D73720a242F70Df785F8028B4D9090Ca64ca39",160000],
      ["0xCbB8966Cf3e4F682a9c3Ca8699Fe7b2BAbd4DfB1",160000],
      ["0x52cD20af48559D586C1BbFC1f9C314142188795f",32143],
      ["0x3a70C22121E69f984F13488c607290e6870B017d",48000],
      ["0x93b11e5a9142Af8fEd3b2c6f0747359d8C4Fd3FF",116595],
      ["0xB68764058616Ff2B704F432f69BFB21F85C06bf7",160000],
      ["0x8BdE98A4Bd8b976F56a6C6075C04c916491d2028",160000],
      ["0x7C74eEE66c15fE55FbC9e1DD8121DB3CF53367fa",29599],
      ["0x4b3787E880497b235baB97b2e9283eA2E77b0fd1",78400],
      ["0xfDeE92fF3e8dEBD646C9b168c1FC273171220D17",20529],
      ["0x19A0a231D0d0B25300a371eD36d74752E3bE00Aa",48000],
      ["0xb0393d7F49Fae7ed1599B092346a705Aa93a04D5",159988],
      ["0x2843f4f6f09566ABA98C59DcA7a41346178E3E5F",160000],
      ["0x4b6bC66Bb306ca8754fA0D4cCA23f0d16Df82Aed",19191],
      ["0x14FfFAA781A3A113d963598483CBE6D278798989",25588],
      ["0x413013FCEf82B09Bf92C7754276a575759f4bF9A",160000],
      ["0xFD90a6aF5670A1fffAAa993Bf1840E190a350D91",308080],
      ["0x2cbaD3180eF028B8A07Cb701Ceb4570d5dCE6FaB",23916],
      ["0x22D3CE114c31dd941C7DBc1B2E6974ef258b2bD2",18145]
    ]

    const Vesting = await ethers.getContractFactory("VestingV2");
    const vesting = await Vesting.attach(vestingAddress);//wethAddress temp subbing in for governance
    await vesting.deployed();
    console.log("VestingV2 deployed to: ", vesting.address);

    let sum = 0;
    for(let i = 0; i<24; i++){
      sum = sum + users[i][1];
    }
    const GFI = await ethers.getContractFactory("GravityToken");
    const gfi = await GFI.attach(gfiAddress);


    sum = sum.toString() + "000000000000000000";
    await gfi.approve(vesting.address, sum);
    console.log("Sum: ", sum);

    for(let i = 0; i<24; i++){
      console.log("Address: ", users[i][0], " Amount: ", users[i][1].toString() + "000000000000000000");
      await vesting.addUser(users[i][0], users[i][1].toString() + "000000000000000000");
    }

    await vesting.transferOwnership("0xeb678812778B68a48001B4A9A4A04c4924c33598");
    console.log("Vesting New Owner: ", await vesting.owner());
    
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });