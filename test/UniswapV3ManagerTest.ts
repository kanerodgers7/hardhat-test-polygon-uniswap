import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

// Replace with your actual contract address
describe("UniswapV3ManagerTest", async () => {
    let weth: any;
    let usdc: any;
    let uni: any;
    let pst: any;
    let donate: any;
    let factory: any;
    let testManager: any;
    let deployer: any;
    
    beforeEach(async function () {
        [deployer] = await ethers.getSigners();
        const factoryERC20 = await ethers.getContractFactory("ERC20Mintable");
        const factoryPST = await ethers.getContractFactory("PSToken");
        do {
            weth = await factoryERC20.deploy("USDC", "USDC", 18) as any;
            usdc = await factoryERC20.deploy("Ether", "ETH", 18) as any;
            pst = await factoryPST.deploy("PST Token", "PST", deployer, 18) as any;
            uni = await factoryERC20.deploy("Uniswap Coin", "UNI", 18) as any;
            donate = await factoryERC20.deploy("Donate Token", "DNT", 18) as any;
        } while(weth.target.toUpperCase() > usdc.target.toUpperCase() || usdc.target.toUpperCase() > pst.target.toUpperCase() || pst.target.toUpperCase() > uni.target.toUpperCase() );


        const factoryFactory = await ethers.getContractFactory("StratoSwapFactory");
        factory = await factoryFactory.deploy();

        // const factoryPool = await ethers.getContractFactory("UniswapV3Pool");
        // pool = await factoryPool.deploy();

        const factoryTestManager = await ethers.getContractFactory("UniswapV3ManagerTest");
        testManager = await factoryTestManager.deploy();

        await testManager.setUp(weth, usdc, uni, pst, donate, factory);
        
        return {deployer, weth, usdc, uni, pst, donate, factory, testManager};
    });

    it('Test mint range', async () => {
        await testManager.testMintInRange();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint range below', async () => {
        await testManager.testMintRangeBelow();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint range above', async () => {
        await testManager.testMintRangeAbove();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
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
        if(failed === true) console.log(message);
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
        if(failed === true) console.log("error", message);
        expect(failed).to.equal(false)
    })

    it('Test mint insufficient token balance', async () => {
        await testManager.testMintInsufficientTokenBalance();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint slippage protection', async () => {
        await testManager.testMintSlippageProtection();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy multi pool', async () => {
        await testManager.testSwapBuyMultipool();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy eth not enough liquidity', async () => {
        await testManager.testSwapBuyEthNotEnoughLiquidity();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy usdc not enough liquidity', async () => {
        await testManager.testSwapBuyUSDCNotEnoughLiquidity();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    // PST Relation
    it('Test mint range below with pst', async () => {
        await testManager.testMintRangeBelowWithPST();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint range above with pst', async () => {
        await testManager.testMintRangeAboveWithPST();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint invalid tick range lower with pst', async () => {
        await testManager.testMintInvalidTickRangeLowerWithPST();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test mint invalid tick range upper with pst', async () => {
        await testManager.testMintInvalidTickRangeUpperWithPST();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })
    it('Test Burn', async () => {
        await testManager.testBurn();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })
    it('Test Single Swap and Collect Fee', async () => {
        await testManager.testSingleSwapAndCollectFee();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })
    it('Test Multi Swap and Collect Fee', async () => {
        await testManager.testMultiSwapAndCollectFee();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test donate', async () => {
        await testManager.testDonate();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test Project', async () => {
        await testManager.testProject();
        const failed = await testManager.getFailedStatus();
        const message = await testManager.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

});