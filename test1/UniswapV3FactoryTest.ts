import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

import { UniswapV3FactoryTest } from '../typechain';


// Replace with your actual contract address
describe("UniswapV3FactoryTest", async () => {
    let uniswapFactory: UniswapV3FactoryTest;
    
    beforeEach(async function () {
        const factory = await ethers.getContractFactory("UniswapV3FactoryTest");
        uniswapFactory = await factory.deploy() as UniswapV3FactoryTest;

        await uniswapFactory.setUp();
    });

    it('Test create pool', async () => {
        await uniswapFactory.testCreatePool();
        expect(await uniswapFactory.failed()).to.eq(false)
    })

    it('Test create pool unsupported fee', async () => {
        await uniswapFactory.testCreatePoolUnsupportedFee();
        expect(await uniswapFactory.failed()).to.eq(false)
    })

    it('Test create pool identical tokens', async () => {
        await uniswapFactory.testCreatePoolIdenticalTokens();
        expect(await uniswapFactory.failed()).to.eq(false)
    })

    it('Test create zero token address', async () => {
        await uniswapFactory.testCreateZeroTokenAddress();
        expect(await uniswapFactory.failed()).to.eq(false)
    })

    it('Test create already exists', async () => {
        await uniswapFactory.testCreateAlreadyExists();
        expect(await uniswapFactory.failed()).to.eq(false)
    })
});