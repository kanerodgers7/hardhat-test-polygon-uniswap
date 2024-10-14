const { ethers } = require("ethers");
const dotenv = require("dotenv");
dotenv.config();

async function getAndCollectFee() {
  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  const managerContract = require("../artifacts/contracts/StratoSwapManager.sol/StratoSwapManager.json");
  const managerHelperContract = require("../artifacts/contracts/StratoSwapManagerHelper.sol/StratoSwapManagerHelper.json");
  const amoyProvider = ethers.getDefaultProvider("https://polygon-amoy.drpc.org");
  const signer = new ethers.Wallet(String(PRIVATE_KEY), amoyProvider);

  const pstAddress = "0xa3cFcD9cCa16a20EFd2c6018eFf0d2549A4a41fc";
  const usdcAddress = "0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582";
  const managerAddress = "0x3edb233340e9FfbDa2A1B4C63f606A9BC628eB7C";
  const managerhelperAddress = "0xA514Ee86866F196caD7f65809C4064041cE2d1Ae";

  const ManagerContract = new ethers.Contract(managerAddress, managerContract.abi, signer);
  const ManagerHelperContract = new ethers.Contract(managerhelperAddress, managerHelperContract.abi, signer);

  try {
    const collect = await ManagerContract.collect({
      tokenA: usdcAddress,
      tokenB: pstAddress,
      fee: 500,
      recipient: signer.address,
      lowerTick: 264000,
      upperTick: 336000,
      amount0Desired: BigInt(1009000631919287742186),
      amount1Desired: BigInt(9529654148120857682742),
    });
    await collect.wait();
    console.log("collect", collect);

    const accumlatedFeeLPAfter = await ManagerHelperContract.getAccumulatedFeeAmount(
      signer.address,
      usdcAddress,
      pstAddress,
      500,
      264000,
      336000
    );
    console.log("Accumulated Fee for LP after", accumlatedFeeLPAfter);
  } catch (error) {
    console.log(error);
  }
}

getAndCollectFee();