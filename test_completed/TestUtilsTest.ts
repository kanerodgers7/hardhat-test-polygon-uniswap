import "@nomicfoundation/hardhat-toolbox";
 
import { expect } from 'chai';
import { ethers } from 'hardhat';

// Replace with your actual contract address
describe("TestUtils Test", () => {
    let testUtils: any;
    
    beforeEach(async function () {
        const factory = await ethers.getContractFactory("TestUtilsTest");
        testUtils = await factory.deploy();
        return {testUtils};
    });

    it('Get test nearest usable tick', async () => {
        await testUtils.testNearestUsableTick();
        const failed = await testUtils.getFailedStatus();
        const message = await testUtils.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Get test tick60', async () => {
        await testUtils.testTick60();
        const failed = await testUtils.getFailedStatus();
        const message = await testUtils.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })

    it('Get test sqrtP60', async () => {
        await testUtils.testSqrtP60();
        const failed = await testUtils.getFailedStatus();
        const message = await testUtils.getErrorMessage();
        // if(failed === true) console.log(message);
        expect(failed).to.equal(false)
    })
});