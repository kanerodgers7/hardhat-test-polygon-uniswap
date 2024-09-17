import { ethers } from "hardhat";
require("dotenv").config();


async function main() {
  const [deployer] = await ethers.getSigners();
  const tokenName = process.env.TOKEN_NAME || "PSToken";
  const tokenSymbol = process.env.TOKEN_SYMBOL || "PST-AMZ";
  const feeAddress = process.env.FEE_ADDRESS || deployer.address;
  const tokenDecimal = process.env.TOKEN_DECIMAL || 18;

  console.log("Deploying contracts with the account:", deployer.address);

  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Account balance:", balance.toString());
  
  const UniswapV3FactoryFact = await ethers.getContractFactory('UniswapV3Factory');
  const UniswapV3QuoterFact = await ethers.getContractFactory('UniswapV3Quoter');
  const UniswapV3ManagerFact = await ethers.getContractFactory('UniswapV3Manager');

  // const uniswapV3Factory = await UniswapV3FactoryFact.deploy();
  // await uniswapV3Factory.waitForDeployment();

  // console.log("UniswapV3Factory deployed to:", uniswapV3Factory.target);
  
  // const uniswapV3Quoter = await UniswapV3QuoterFact.deploy(uniswapV3Factory.target);
  // await uniswapV3Quoter.waitForDeployment();

  // console.log("UniswapV3QuoterFact deployed to:", uniswapV3Quoter.target);

  const uniswapV3Manager = await UniswapV3ManagerFact.deploy("0x8424BB4116271e4ADDdAb18aD53e01d6057fff95");
  await uniswapV3Manager.waitForDeployment();

  console.log("UniswapV3ManagerFact deployed to:", uniswapV3Manager.target);
  
  console.log('All done');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
