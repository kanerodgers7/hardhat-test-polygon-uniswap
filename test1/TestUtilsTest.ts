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
        // const temp = await testUtils.testNearestUsableTick();
        // console.log("temp", temp);
        // console.log(await testUtils.testNearestUsableTick());
        // expect(await testUtils.testNearestUsableTick()).to.equal(true)
        const tx = await testUtils.testNearestUsableTick();
        const receipt = await tx.wait();

        console.log("receipt", receipt);
        receipt.events.forEach((event) => {
            console.log(`Event: ${event.event}`);
            event.args.forEach((arg, index) => {
                console.log(`  Arg ${index}: ${arg}`);
            });
        });
    })

    // it('Get test tick60', async () => {
    //     await testUtils.testTick60();
    //     expect(await testUtils.failed()).to.eq(false)
    // })

    // it('Get test sqrtP60', async () => {
    //     await testUtils.testSqrtP60();
    //     expect(await testUtils.failed()).to.eq(false)
    // })
});