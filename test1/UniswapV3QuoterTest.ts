import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

import { UniswapV3QuoterTest } from '../typechain';


// Replace with your actual contract address
describe("UniswapV3QuoterTest", async () => {
    let uniswapV3Quoter: UniswapV3QuoterTest;
    
    beforeEach(async function () {
        const factory = await ethers.getContractFactory("UniswapV3QuoterTest");
        uniswapV3Quoter = await factory.deploy() as UniswapV3QuoterTest;

        await uniswapV3Quoter.setUp();
    });

    it('Test quote usdc for ether', async () => {
        await uniswapV3Quoter.testQuoteUSDCforETH();
        expect(await uniswapV3Quoter.failed()).to.eq(false)
    })

    it('Test quote ether for usdc', async () => {
        await uniswapV3Quoter.testQuoteETHforUSDC();
        expect(await uniswapV3Quoter.failed()).to.eq(false)
    })

    it('Test quote uni for usdc via ether', async () => {
        await uniswapV3Quoter.testQuoteUNIforUSDCviaETH();
        expect(await uniswapV3Quoter.failed()).to.eq(false)
    })

    it('Test quote and swap uni for usdc via ether', async () => {
        await uniswapV3Quoter.testQuoteAndSwapUNIforUSDCviaETH();
        expect(await uniswapV3Quoter.failed()).to.eq(false)
    })

    it('Test quote and swap usdc for ether', async () => {
        await uniswapV3Quoter.testQuoteAndSwapUSDCforETH();
        expect(await uniswapV3Quoter.failed()).to.eq(false)
    })

    it('Test quote and swap ether for usdc', async () => {
        await uniswapV3Quoter.testQuoteAndSwapETHforUSDC();
        expect(await uniswapV3Quoter.failed()).to.eq(false)
    })

});