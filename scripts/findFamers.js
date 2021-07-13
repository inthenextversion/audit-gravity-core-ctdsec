const { ethers } = require("hardhat");
const data = require('./Farmers.json');
let rows = [];
async function main() {
    const Farm_ADDRESS = "0x3C68CE8504087f89c640D02d133646d98e64ddd9";
    [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log(data['data']['farmers'][0]['user']);

    const Farm = await ethers.getContractFactory("Farm_Contract");
    const farm = await Farm.attach("0xFa56a0f01863c034b55e904C9c39213E44D92Af7");
    let reward;
    let amount;
    let address;
    let total = 0;
    for(let i=1; i<93; i++){
        address = data['data']['farmers'][i]['user'];
        amount =  Number(data['data']['farmers'][i]['amount'])/10**18;
        reward = Number(await farm.pendingReward(address)) /10**18;
        rows.push([address, amount, reward]);
        console.log(address, amount, reward);
        total = total + amount;
        //if(reward < 10){
        //    console.log(reward);
        //}
    }
    console.log("Total Amount in Farm: ", total);

    

  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });