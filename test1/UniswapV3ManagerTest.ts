import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

import { UniswapV3ManagerTest } from '../typechain';


// Replace with your actual contract address
describe("UniswapV3ManagerTest", async () => {
    let uniswapManager: UniswapV3ManagerTest;
    
    beforeEach(async function () {
        const factory = await ethers.getContractFactory("UniswapV3ManagerTest");
        uniswapManager = await factory.deploy() as UniswapV3ManagerTest;

        await uniswapManager.setUp();
    });

    it('Test mint range', async () => {
        await uniswapManager.testMintInRange();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test mint range below', async () => {
        await uniswapManager.testMintRangeBelow();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test mint range above', async () => {
        await uniswapManager.testMintRangeAbove();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test mint overlapping ranges', async () => {
        await uniswapManager.testMintOverlappingRanges();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test mint partially overlapping ranges', async () => {
        await uniswapManager.testMintPartiallyOverlappingRanges();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test mint invalid tick range lower', async () => {
        await uniswapManager.testMintInvalidTickRangeLower();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test mint invalid tick range upper', async () => {
        await uniswapManager.testMintInvalidTickRangeUpper();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test mint zero liquidity', async () => {
        await uniswapManager.testMintZeroLiquidity();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test mint insufficient token balance', async () => {
        await uniswapManager.testMintInsufficientTokenBalance();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test mint slippage protection', async () => {
        await uniswapManager.testMintSlippageProtection();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test swap buy eth', async () => {
        await uniswapManager.testSwapBuyEth();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test swap buy usdc', async () => {
        await uniswapManager.testSwapBuyUSDC();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test swap buy multi pool', async () => {
        await uniswapManager.testSwapBuyMultipool();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test swap mixed', async () => {
        await uniswapManager.testSwapMixed();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test swap buy eth not enough liquidity', async () => {
        await uniswapManager.testSwapBuyEthNotEnoughLiquidity();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test swap buy usdc not enough liquidity', async () => {
        await uniswapManager.testSwapBuyUSDCNotEnoughLiquidity();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test swap insucfficient input amount', async () => {
        await uniswapManager.testSwapInsufficientInputAmount();
        expect(await uniswapManager.failed()).to.eq(false)
    })

    it('Test get position', async () => {
        await uniswapManager.testGetPosition();
        expect(await uniswapManager.failed()).to.eq(false)
    })
});