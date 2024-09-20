import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

import { UniswapV3QuoterTest } from '../typechain';


// Replace with your actual contract address
describe("UniswapV3QuoterTest", async () => {
    let weth: any;
    let usdc: any;
    let uni: any;
    let factory: any;
    let testQuoter: any;
    
    beforeEach(async function () {
        const factoryERC20 = await ethers.getContractFactory("ERC20Mintable");
        weth = await factoryERC20.deploy("USDC", "USDC", 18) as any;
        usdc = await factoryERC20.deploy("Ether", "ETH", 18) as any;
        uni = await factoryERC20.deploy("Uniswap Coin", "UNI", 18) as any;

        const factoryFactory = await ethers.getContractFactory("UniswapV3Factory");
        factory = await factoryFactory.deploy();
        
        const factoryQuoter = await ethers.getContractFactory("UniswapV3QuoterTest");
        testQuoter = await factoryQuoter.deploy();
        
        await testQuoter.setUp(weth, usdc, uni, factory);
        
        return { weth, usdc, uni, factory, testQuoter };
    });

    it('Test quote usdc for ether', async () => {
        await testQuoter.testQuoteUSDCforETH();
        const failed = await testQuoter.getFailedStatus();
        const message = await testQuoter.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test quote ether for usdc', async () => {
        await testQuoter.testQuoteETHforUSDC();
        const failed = await testQuoter.getFailedStatus();
        const message = await testQuoter.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test quote uni for usdc via ether', async () => {
        await testQuoter.testQuoteUNIforUSDCviaETH();
        const failed = await testQuoter.getFailedStatus();
        const message = await testQuoter.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test quote and swap uni for usdc via ether', async () => {
        await testQuoter.testQuoteAndSwapUNIforUSDCviaETH();
        const failed = await testQuoter.getFailedStatus();
        const message = await testQuoter.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test quote and swap usdc for ether', async () => {
        await testQuoter.testQuoteAndSwapUSDCforETH();
        const failed = await testQuoter.getFailedStatus();
        const message = await testQuoter.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test quote and swap ether for usdc', async () => {
        await testQuoter.testQuoteAndSwapETHforUSDC();
        const failed = await testQuoter.getFailedStatus();
        const message = await testQuoter.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

});