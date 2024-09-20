import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';


// Replace with your actual contract address
describe("UniswapV3PoolTest", async () => {
    let weth: any;
    let usdc: any;
    let factory: any;
    let testPoolSwap: any;
    
    beforeEach(async function () {
        const factoryERC20 = await ethers.getContractFactory("ERC20Mintable");
        weth = await factoryERC20.deploy("USDC", "USDC", 18) as any;
        usdc = await factoryERC20.deploy("Ether", "ETH", 18) as any;

        const factoryFactory = await ethers.getContractFactory("UniswapV3Factory");
        factory = await factoryFactory.deploy();
        
        const factoryTestManager = await ethers.getContractFactory("UniswapV3PoolTest");
        testPoolSwap = await factoryTestManager.deploy();

        await testPoolSwap.setUp(weth, usdc, factory);

        return {weth, usdc, factory, testPoolSwap};
    });

    it('Test initialize', async () => {
        await testPoolSwap.testInitialize();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test mint in range', async () => {
        await testPoolSwap.testMintInRange();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test mint range below', async () => {
        await testPoolSwap.testMintRangeBelow();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test mint range above', async () => {
        await testPoolSwap.testMintRangeAbove();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test mint overlapping ranges', async () => {
        await testPoolSwap.testMintOverlappingRanges();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test burn', async () => {
        await testPoolSwap.testBurn();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test burn partially', async () => {
        await testPoolSwap.testBurnPartially();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test collect', async () => {
        await testPoolSwap.testCollect();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test collect after zero burn', async () => {
        await testPoolSwap.testCollectAfterZeroBurn();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test collect more than available', async () => {
        await testPoolSwap.testCollectMoreThanAvailable();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test collect partially', async () => {
        await testPoolSwap.testCollectPartially();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test mint invalid tick range lower', async () => {
        await testPoolSwap.testMintInvalidTickRangeLower();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test mint invalid tick range upper', async () => {
        await testPoolSwap.testMintInvalidTickRangeUpper();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test mint zero liquidity', async () => {
        await testPoolSwap.testMintZeroLiquidity();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })


    it('Test mint insufficient token balance', async () => {
        await testPoolSwap.testMintInsufficientTokenBalance();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })
});