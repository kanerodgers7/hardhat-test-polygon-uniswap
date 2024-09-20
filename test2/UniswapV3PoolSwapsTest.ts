import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';


// Replace with your actual contract address
describe("UniswapV3PoolSwapsTest", async () => {
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
        
        const factoryTestManager = await ethers.getContractFactory("UniswapV3PoolSwapsTest");
        testPoolSwap = await factoryTestManager.deploy();

        await testPoolSwap.setUp(weth, usdc, factory);

        return {weth, usdc, factory, testPoolSwap};
    });

    it('Test buy ether one price range', async () => {
        await testPoolSwap.testBuyETHOnePriceRange();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test buy ether equal price ranges', async () => {
        await testPoolSwap.testBuyETHTwoEqualPriceRanges();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test buy ether consecutive price ranges', async () => {
        await testPoolSwap.testBuyETHConsecutivePriceRanges();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test buy ether partially overlapping price ranges', async () => {
        await testPoolSwap.testBuyETHPartiallyOverlappingPriceRanges();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test buy ether slippage interruption', async () => {
        await testPoolSwap.testBuyETHSlippageInterruption();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test buy usdc one price range', async () => {
        await testPoolSwap.testBuyUSDCOnePriceRange();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test buy usdc two equal price ranges', async () => {
        await testPoolSwap.testBuyUSDCTwoEqualPriceRanges();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test buy usdc consecutive price ranges', async () => {
        await testPoolSwap.testBuyUSDCConsecutivePriceRanges();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test buy usdc partially overlapping price ranges', async () => {
        await testPoolSwap.testBuyUSDCPartiallyOverlappingPriceRanges();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test buy usdc slippage interruption', async () => {
        await testPoolSwap.testBuyUSDCSlippageInterruption();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy ether not enough liquidity', async () => {
        await testPoolSwap.testSwapBuyEthNotEnoughLiquidity();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap buy usdc not enough liquidity', async () => {
        await testPoolSwap.testSwapBuyUSDCNotEnoughLiquidity();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap mixed', async () => {
        await testPoolSwap.testSwapMixed();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test swap insufficient input amount', async () => {
        await testPoolSwap.testSwapInsufficientInputAmount();
        const failed = await testPoolSwap.getFailedStatus();
        const message = await testPoolSwap.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })
});