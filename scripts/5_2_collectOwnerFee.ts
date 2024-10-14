const { ethers } = require("ethers");
const dotenv = require("dotenv");
dotenv.config();

async function getAndCollectOwnerFee() {
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
    const collectOwnerFee = await ManagerContract.colletOwnerFee({
      tokenA: usdcAddress,
      tokenB: pstAddress,
      fee: 500,
      recipient: signer.address,
    });
    await collectOwnerFee.wait();
    console.log("collectOwnerFee", collectOwnerFee);
  } catch (error) {
    console.log(error);
  }
}

getAndCollectOwnerFee();