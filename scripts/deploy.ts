import * as fs from 'fs';
import hre, { ethers } from "hardhat";

import {
  UniswapV3Factory,
  UniswapV3Quoter,
  UniswapV3Manager,
  // UniswapV3Pool,
} from '../typechain/pulse';

const addressFile = 'contract_addresses.md';

// const verify = async (addr: string, args: any[]) => {
//   try {
//     await hre.run('verify:verify', {
//       address: addr,
//       constructorArguments: args
//     });
//   } catch (ex: any) {
//     if (ex.toString().indexOf('Already Verified') == -1) {
//       throw ex;
//     }
//   }
// };

async function main() {
  console.log('Starting deployments');
  const accounts = await hre.ethers.getSigners();

  const deployer = accounts[0];

  const UniswapV3FactoryFact = await ethers.getContractFactory('UniswapV3Factory');
  const UniswapV3QuoterFact = await ethers.getContractFactory('UniswapV3Quoter');
  const UniswapV3ManagerFact = await ethers.getContractFactory('UniswapV3Manager');
  // const UniswapV3PoolFact = await ethers.getContractFactory('UniswapV3Pool');

  const uniswapV3Factory = (await UniswapV3FactoryFact.connect(
    deployer
  ).deploy()) as UniswapV3Factory;
  await uniswapV3Factory.deployed();

  const uniswapV3Quoter = (await UniswapV3QuoterFact.connect(deployer).deploy([
    uniswapV3Factory.address
  ])) as UniswapV3Quoter;
  await uniswapV3Quoter.deployed();

  const uniswapV3Manager = (await UniswapV3ManagerFact.connect(deployer).deploy([
    uniswapV3Factory.address
  ])) as UniswapV3Manager;
  await uniswapV3Manager.deployed();

  const writeAddr = (addr: string, name: string) => {
    fs.appendFileSync(
      addressFile,
      `${name}: [https://goerli.etherscan.io/address/${addr}](https://goerli.etherscan.io/address/${addr})<br/>`
    );
  };

  if (fs.existsSync(addressFile)) {
    fs.rmSync(addressFile);
  }

  fs.appendFileSync(
    addressFile,
    'This file contains the latest test deployment addresses in the Goerli network<br/>'
  );
  writeAddr(uniswapV3Factory.address, 'UniswapV3Factory');
  writeAddr(uniswapV3Quoter.address, 'UniswapV3Quoter');
  writeAddr(uniswapV3Manager.address, 'UniswapV3Manager');

  console.log('Deployments done, waiting for etherscan verifications');
  // Wait for the contracts to be propagated inside Etherscan
  await new Promise((f) => setTimeout(f, 60000));

  // await verify(uniswapV3Factory.address, []);
  // await verify(uniswapV3Quoter.address, [[uniswapV3Factory.address]]);
  // await verify(uniswapV3Manager.address, [[uniswapV3Factory.address]]);

  console.log('All done');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
