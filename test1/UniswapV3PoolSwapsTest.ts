import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

import { UniswapV3PoolSwapsTest } from '../typechain';


// Replace with your actual contract address
describe("UniswapV3PoolSwapsTest", async () => {
    let uniswapV3PoolSwaps: UniswapV3PoolSwapsTest;
    
    beforeEach(async function () {
        const factory = await ethers.getContractFactory("UniswapV3PoolSwapsTest");
        uniswapV3PoolSwaps = await factory.deploy() as UniswapV3PoolSwapsTest;

        await uniswapV3PoolSwaps.setUp();
    });

    it('Test buy ether one price range', async () => {
        await uniswapV3PoolSwaps.testBuyETHOnePriceRange();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test buy ether equal price ranges', async () => {
        await uniswapV3PoolSwaps.testBuyETHTwoEqualPriceRanges();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test buy ether consecutive price ranges', async () => {
        await uniswapV3PoolSwaps.testBuyETHConsecutivePriceRanges();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test buy ether partially overlapping price ranges', async () => {
        await uniswapV3PoolSwaps.testBuyETHPartiallyOverlappingPriceRanges();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test buy ether slippage interruption', async () => {
        await uniswapV3PoolSwaps.testBuyETHSlippageInterruption();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test buy usdc one price range', async () => {
        await uniswapV3PoolSwaps.testBuyUSDCOnePriceRange();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test buy usdc two equal price ranges', async () => {
        await uniswapV3PoolSwaps.testBuyUSDCTwoEqualPriceRanges();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test buy usdc consecutive price ranges', async () => {
        await uniswapV3PoolSwaps.testBuyUSDCConsecutivePriceRanges();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test buy usdc partially overlapping price ranges', async () => {
        await uniswapV3PoolSwaps.testBuyUSDCPartiallyOverlappingPriceRanges();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test buy usdc slippage interruption', async () => {
        await uniswapV3PoolSwaps.testBuyUSDCSlippageInterruption();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test swap buy ether not enough liquidity', async () => {
        await uniswapV3PoolSwaps.testSwapBuyEthNotEnoughLiquidity();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test swap buy usdc not enough liquidity', async () => {
        await uniswapV3PoolSwaps.testSwapBuyUSDCNotEnoughLiquidity();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test swap mixed', async () => {
        await uniswapV3PoolSwaps.testSwapMixed();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })

    it('Test swap insufficient input amount', async () => {
        await uniswapV3PoolSwaps.testSwapInsufficientInputAmount();
        expect(await uniswapV3PoolSwaps.failed()).to.eq(false)
    })
});