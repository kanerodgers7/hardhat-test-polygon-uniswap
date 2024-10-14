const { ethers } = require("ethers");
const dotenv = require("dotenv");
const readline = require('readline');
dotenv.config();

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function question(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

async function estimateAndSwap() {
    const PRIVATE_KEY = process.env.USER_PRIVATE_KEY;
    const PST_ADDRESS = "0xa3cFcD9cCa16a20EFd2c6018eFf0d2549A4a41fc";
    const USDC_ADDRESS = "0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582";

    const managerHelperContract = require("../artifacts/contracts/StratoSwapManagerHelper.sol/StratoSwapManagerHelper.json");
    const managerContract = require("../artifacts/contracts/StratoSwapManager.sol/StratoSwapManager.json");

    const amoyProvider = ethers.getDefaultProvider("https://polygon-amoy.drpc.org");
    const signer = new ethers.Wallet(String(PRIVATE_KEY), amoyProvider);

    const managerhelperAddress = "0xA514Ee86866F196caD7f65809C4064041cE2d1Ae";
    const managerAddress = "0x3edb233340e9FfbDa2A1B4C63f606A9BC628eB7C";

    const ManagerHelperContract = new ethers.Contract(managerhelperAddress, managerHelperContract.abi, signer);
    const ManagerContract = new ethers.Contract(managerAddress, managerContract.abi, signer);

    try {
        // User input for swap direction
        const swapDirection = await question("Enter '1' for USDC to PST, or '2' for PST to USDC: ");
        const isUsdcToPst = swapDirection === '1';

        // User input for amount to swap
        const amountInput = await question(`Enter the amount of ${isUsdcToPst ? 'USDC' : 'PST'} to swap: `);
        const amountIn = isUsdcToPst 
            ? ethers.parseUnits(amountInput, 6)  // USDC has 6 decimals
            : ethers.parseUnits(amountInput, 18);  // PST has 18 decimals

        // Estimation
        console.log("Estimating swap...");
        // or can run it here https://amoy.polygonscan.com/address/0xa514ee86866f196cad7f65809c4064041ce2d1ae#readContract
        const { amount0, amount1 } = await ManagerHelperContract.getTotalVolumeOfPool(USDC_ADDRESS, PST_ADDRESS, 500);
        console.log("Pool Volumes:");
        console.log("USDC:", amount0.toString());
        console.log("PST:", amount1.toString());

        const [reserveIn, reserveOut] = isUsdcToPst ? [amount0, amount1] : [amount1, amount0];
        const amountInWithFee = amountIn * BigInt(997); // 0.3% fee
        const numerator = amountInWithFee * reserveOut;
        const denominator = (reserveIn * BigInt(1000)) + amountInWithFee;
        const estimatedOut = numerator / denominator;

        console.log(`Estimating swap of ${ethers.formatUnits(amountIn, isUsdcToPst ? 6 : 18)} ${isUsdcToPst ? 'USDC' : 'PST'}`);
        console.log(`Estimated output: ${ethers.formatUnits(estimatedOut, isUsdcToPst ? 18 : 6)} ${isUsdcToPst ? 'PST' : 'USDC'}`);

        const priceImpact = (amountIn * BigInt(10000) / reserveIn);
        console.log(`Estimated price impact: ${(Number(priceImpact) / 100).toFixed(2)}%`);

        // Ask user if they want to proceed with the swap
        const userResponse = await question('Do you want to proceed with the swap? (yes/no): ');

        if (userResponse.toLowerCase() !== 'yes') {
            console.log("Swap cancelled by user.");
            return;
        }

        // Proceed with swap
        console.log("Performing the swap...");
        const swap = await ManagerContract.swapSingle({
            tokenIn: isUsdcToPst ? USDC_ADDRESS : PST_ADDRESS,
            tokenOut: isUsdcToPst ? PST_ADDRESS : USDC_ADDRESS,
            fee: 500,
            amountIn: amountIn,
        });
        await swap.wait();
        console.log("Swap transaction:", swap.hash);

    } catch (error) {
        console.error("Error during estimation or swap:", error);
    } finally {
        rl.close();
    }
}

estimateAndSwap().then(() => {
    console.log("Process complete.");
}).catch(error => {
    console.error("Unhandled error:", error);
});