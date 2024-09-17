import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

// Replace with your actual contract address
describe("UniswapV3FactoryTest", () => {
    let uniswapFactory: any;
    let factory: any;
    let weth: any;
    let usdc: any;
    
    beforeEach(async function () {
        const uniswapfactory = await ethers.getContractFactory("UniswapV3FactoryTest");
        uniswapFactory = await uniswapfactory.deploy();

        const kkkfactory = await ethers.getContractFactory("UniswapV3Factory");
        factory = await kkkfactory.deploy();

        const erc20Factory1 = await ethers.getContractFactory("ERC20Mintable");
        weth = await erc20Factory1.deploy("Ether", "ETH", 18);
        const erc20Factory2 = await ethers.getContractFactory("ERC20Mintable");
        usdc = await erc20Factory2.deploy("USDC", "USDC", 18);
        // await uniswapFactory.setUp();
        return {uniswapFactory, factory, weth, usdc};
    });

    it('Test create pool', async () => {
        await uniswapFactory.testCreatePool(factory.target, weth.target, usdc.target);
        const failed = await uniswapFactory.getFailedStatus();
        const message = await uniswapFactory.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test create pool unsupported fee', async () => {
        await uniswapFactory.testCreatePoolUnsupportedFee(factory.target, weth.target, usdc.target);
        const failed = await uniswapFactory.getFailedStatus();
        const message = await uniswapFactory.getErrorMessage();
        if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test create pool identical tokens', async () => {
        await uniswapFactory.testCreatePoolIdenticalTokens(factory.target, weth.target);
        const failed = await uniswapFactory.getFailedStatus();
        const message = await uniswapFactory.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test create zero token address', async () => {
        await uniswapFactory.testCreateZeroTokenAddress(factory.target, weth.target);
        const failed = await uniswapFactory.getFailedStatus();
        const message = await uniswapFactory.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Test create already exists', async () => {
        await uniswapFactory.testCreateAlreadyExists(factory.target, weth.target, usdc.target);
        const failed = await uniswapFactory.getFailedStatus();
        const message = await uniswapFactory.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })
});