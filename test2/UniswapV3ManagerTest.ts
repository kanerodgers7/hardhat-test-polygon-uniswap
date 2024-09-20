import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

// Replace with your actual contract address
describe("UniswapV3ManagerTest", async () => {
    let weth: any;
    let usdc: any;
    let uni: any;
    let factory: any;
    let manager: any;
    let testManager: any;
    
    beforeEach(async function () {
        const factoryERC20 = await ethers.getContractFactory("ERC20Mintable");
        weth = await factoryERC20.deploy("USDC", "USDC", 18) as any;
        usdc = await factoryERC20.deploy("Ether", "ETH", 18) as any;
        uni = await factoryERC20.deploy("Uniswap Coin", "UNI", 18) as any;

        const factoryFactory = await ethers.getContractFactory("UniswapV3Factory");
        factory = await factoryFactory.deploy();

        // const factoryPool = await ethers.getContractFactory("UniswapV3Pool");
        // pool = await factoryPool.deploy();

        const factoryManager = await ethers.getContractFactory("UniswapV3Manager");
        manager = await factoryManager.deploy(factory.target);
        
        const factoryTestManager = await ethers.getContractFactory("UniswapV3ManagerTest");
        testManager = await factoryTestManager.deploy();

        await testManager.setUp(weth, usdc, uni, factory, manager);
        
        return {weth, usdc, uni, factory, manager, testManager};
    });

    it('Test mint range', async () => {
        await testManager.testMintInRange();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint range below', async () => {
        await testManager.testMintRangeBelow();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint range above', async () => {
        await testManager.testMintRangeAbove();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint overlapping ranges', async () => {
        await testManager.testMintOverlappingRanges();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint partially overlapping ranges', async () => {
        await testManager.testMintPartiallyOverlappingRanges();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint invalid tick range lower', async () => {
        await testManager.testMintInvalidTickRangeLower();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint invalid tick range upper', async () => {
        await testManager.testMintInvalidTickRangeUpper();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint zero liquidity', async () => {
        await testManager.testMintZeroLiquidity();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint insufficient token balance', async () => {
        await testManager.testMintInsufficientTokenBalance();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint slippage protection', async () => {
        await testManager.testMintSlippageProtection();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy eth', async () => {
        await testManager.testSwapBuyEth();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy usdc', async () => {
        await testManager.testSwapBuyUSDC();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy multi pool', async () => {
        await testManager.testSwapBuyMultipool();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap mixed', async () => {
        await testManager.testSwapMixed();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy eth not enough liquidity', async () => {
        await testManager.testSwapBuyEthNotEnoughLiquidity();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy usdc not enough liquidity', async () => {
        await testManager.testSwapBuyUSDCNotEnoughLiquidity();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap insucfficient input amount', async () => {
        await testManager.testSwapInsufficientInputAmount();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test get position', async () => {
        await testManager.testGetPosition();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })
});