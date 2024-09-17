import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

import { UniswapV3PoolTest } from '../typechain';


// Replace with your actual contract address
describe("UniswapV3PoolTest", async () => {
    let uniswapV3Pool: UniswapV3PoolTest;
    
    beforeEach(async function () {
        const factory = await ethers.getContractFactory("UniswapV3PoolTest");
        uniswapV3Pool = await factory.deploy() as UniswapV3PoolTest;

        await uniswapV3Pool.setUp();
    });

    it('Test initialize', async () => {
        await uniswapV3Pool.testInitialize();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test mint in range', async () => {
        await uniswapV3Pool.testMintInRange();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test mint range below', async () => {
        await uniswapV3Pool.testMintRangeBelow();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test mint range above', async () => {
        await uniswapV3Pool.testMintRangeAbove();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test mint overlapping ranges', async () => {
        await uniswapV3Pool.testMintOverlappingRanges();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test burn', async () => {
        await uniswapV3Pool.testBurn();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test burn partially', async () => {
        await uniswapV3Pool.testBurnPartially();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test collect', async () => {
        await uniswapV3Pool.testCollect();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test collect after zero burn', async () => {
        await uniswapV3Pool.testCollectAfterZeroBurn();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test collect more than available', async () => {
        await uniswapV3Pool.testCollectMoreThanAvailable();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test collect partially', async () => {
        await uniswapV3Pool.testCollectPartially();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test mint invalid tick range lower', async () => {
        await uniswapV3Pool.testMintInvalidTickRangeLower();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test mint invalid tick range upper', async () => {
        await uniswapV3Pool.testMintInvalidTickRangeUpper();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test mint zero liquidity', async () => {
        await uniswapV3Pool.testMintZeroLiquidity();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })


    it('Test mint insufficient token balance', async () => {
        await uniswapV3Pool.testMintInsufficientTokenBalance();
        expect(await uniswapV3Pool.failed()).to.eq(false)
    })
});