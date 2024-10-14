const { ethers } = require("ethers");
const dotenv = require("dotenv");
dotenv.config();

async function main() {
  const PRIVATE_KEY = process.env.PRIVATE_KEY;

  const managerContract = require("../artifacts/contracts/StratoSwapManager.sol/StratoSwapManager.json");
  const managerHelperContract = require("../artifacts/contracts/StratoSwapManagerHelper.sol/StratoSwapManagerHelper.json");

  const amoyProvider = ethers.getDefaultProvider(
    "https://polygon-amoy.drpc.org"
  );

  const signer = new ethers.Wallet(String(PRIVATE_KEY), amoyProvider);
  console.log("signer address", signer.address);

  const pstAddress = "0xF77DF44A6A85e84dba5F3DB0A3Ad72879ec70E55"; //update this with contract address you deployed
  const usdtAddress = "0x1Ed1489a79df884BA5c4ED64e8E3D8B82AD5bc68"; //update this with contract address you deployed
  const managerAddress = "0x3edb233340e9FfbDa2A1B4C63f606A9BC628eB7C"; //check whether you approved to this address for PST and USDT
  const managerhelperAddress = "0xA514Ee86866F196caD7f65809C4064041cE2d1Ae";
  const donateTokenAddress = "0x6D502C7Ec05e89aDDBF2B0Cf2Eea28a1534Dd362";

  const ManagerContract = new ethers.Contract(
    managerAddress,
    managerContract.abi,
    signer
  );
  const ManagerHelperContract = new ethers.Contract(
    managerhelperAddress,
    managerHelperContract.abi,
    signer
  );
  try {
    //you can run these functions one by one by blocking others - symple way is to commenting them

    ///Create the Pool with ratio of 1 USDC : 10 PST  **Warning**: this function only works with owner account
    const poolBefore = await ManagerContract.getPoolAddresses();
    console.log("Pool Before:", poolBefore); //checck if pool already exists or not.
    const price = BigInt(10000000000000000000);
    const createPool = await ManagerContract.createPool({
      tokenA: usdtAddress,
      tokenB: pstAddress,
      fee: 3000,
      currentPrice: price,
      tokenDonate: donateTokenAddress,
    });
    await createPool.wait();
    const poolAfter = await ManagerContract.getPoolAddresses();
    console.log("Pool After:", poolAfter);

    ///add liquidity to the pool with custom range.  **Warning**:check your wallet before and after
    const standardSlot = await ManagerHelperContract.getStandardSlot0(
      usdtAddress,
      pstAddress,
      3000
    );
    console.log("Standard Slot", standardSlot); //chceck standard slot
    const addLiquidity = await ManagerContract.mint({
      tokenA: usdtAddress,
      tokenB: pstAddress,
      fee: 3000,
      lowerTick: 20400,
      upperTick: 25860,
      amount0Desired: BigInt(1000000000000000000000),
      amount1Desired: BigInt(10000000000000000000000),
      amount0Min: 0,
      amount1Min: 0,
    }); //these lower and upper tick points are customized, check them with standard slot.
    await addLiquidity.wait();
    console.log("addLiquidity", addLiquidity);

    ///swap PST tokenIn.  **Warning**:check your wallet before and after
    const swap = await ManagerContract.swapSingle({
      tokenIn: pstAddress,
      tokenOut: usdtAddress,
      fee: 3000,
      amountIn: BigInt(10000000000000000000),
    });
    await swap.wait();
    console.log("swap", swap);

    ///burn liquidity.
    const liquidity = await ManagerHelperContract.getLiquidity(
      usdtAddress,
      pstAddress,
      3000,
      signer.address,
      20400,
      25860
    ); //get liquidity amount for LP
    console.log("Liquidity before", liquidity);

    const accumlatedFee = await ManagerHelperContract.getAccumulatedFeeAmount(
      signer.address,
      usdtAddress,
      pstAddress,
      3000,
      20400,
      25860
    );
    console.log("Accumulated Fee before", accumlatedFee);

    const burn = await ManagerContract.burn({
      tokenA: usdtAddress,
      tokenB: pstAddress,
      fee: 3000,
      lowerTick: 20400,
      upperTick: 25860,
      liquidity: BigInt(23944172458381426832882),
    }); //burn token
    await burn.wait();
    console.log("burn", burn);

    const liquidityAfter = await ManagerHelperContract.getLiquidity(
      usdtAddress,
      pstAddress,
      3000,
      signer.address,
      20400,
      25860
    ); //get liquidity amount for LP
    console.log("Liquidity after", liquidityAfter);

    const accumlatedFeeAfter =
      await ManagerHelperContract.getAccumulatedFeeAmount(
        signer.address,
        usdtAddress,
        pstAddress,
        3000,
        20400,
        25860
      );
    console.log("Accumulated Fee after", accumlatedFeeAfter);

    ///collect accumulated fee for LP.  **Warning**:check your wallet before and after
    const accumlatedFeeLP = await ManagerHelperContract.getAccumulatedFeeAmount(
      signer.address,
      usdtAddress,
      pstAddress,
      3000,
      20400,
      25860
    );
    console.log("Accumulated Fee for LP", accumlatedFeeLP);

    const collect = await ManagerContract.collect({
      tokenA: usdtAddress,
      tokenB: pstAddress,
      fee: 3000,
      recipient: signer.address,
      lowerTick: 20400,
      upperTick: 25860,
      amount0Desired: BigInt(1009000631919287742186),
      amount1Desired: BigInt(9529654148120857682742),
    });
    await collect.wait();
    console.log("collect", collect);

    const accumlatedFeeLPAfter =
      await ManagerHelperContract.getAccumulatedFeeAmount(
        signer.address,
        usdtAddress,
        pstAddress,
        3000,
        20400,
        25860
      );
    console.log("Accumulated Fee for LP after", accumlatedFeeLPAfter);

    ///collect owner accumulated fee.  **Warning**:check your wallet before and after
    const accumulatedOwnerFee =
      await ManagerHelperContract.getOwnerAccumulatedFeeAmount(
        usdtAddress,
        pstAddress,
        3000
      ); //check owner accumulated fee before
    console.log("Accumulated Owner Fee:", accumulatedOwnerFee);

    const collectOwnerFee = await ManagerContract.colletOwnerFee({
      tokenA: usdtAddress,
      tokenB: pstAddress,
      fee: 3000,
      recipient: signer.address,
    });
    await collectOwnerFee.wait();
    console.log("collectOwnerFee", collectOwnerFee);
  } catch (error) {
    console.log(error);
  }
}

main();
