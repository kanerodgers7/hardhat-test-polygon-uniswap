const { ethers } = require("ethers");
const dotenv = require("dotenv");
dotenv.config();

async function createPool() {
  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  const managerContract = require("../artifacts/contracts/StratoSwapManager.sol/StratoSwapManager.json");
  const amoyProvider = ethers.getDefaultProvider(
    "https://polygon-amoy.drpc.org"
  );
  const signer = new ethers.Wallet(String(PRIVATE_KEY), amoyProvider);

  const pstAddress = "0xa3cFcD9cCa16a20EFd2c6018eFf0d2549A4a41fc";
  const usdcAddress = "0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582";
  const managerAddress = "0x3edb233340e9FfbDa2A1B4C63f606A9BC628eB7C";
  const donateTokenAddress = "0x6D502C7Ec05e89aDDBF2B0Cf2Eea28a1534Dd362";

  const ManagerContract = new ethers.Contract(
    managerAddress,
    managerContract.abi,
    signer
  );

  try {
    const poolBefore = await ManagerContract.getPoolAddresses();
    console.log("Pool Before:", poolBefore);

    const price = BigInt(10000000000000000000000000000000);
    const createPool = await ManagerContract.createPool({
      tokenA: usdcAddress,
      tokenB: pstAddress,
      fee: 1000, // 500 = 0.05%
      currentPrice: price,
      tokenDonate: donateTokenAddress,
    });
    await createPool.wait();

    const poolAfter = await ManagerContract.getPoolAddresses();
    console.log("Pool After:", poolAfter);
  } catch (error) {
    console.log(error);
  }
}

createPool();
