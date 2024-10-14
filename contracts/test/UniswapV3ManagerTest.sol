// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {Test, stdError} from "forge-std/Test.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./ERC20Mintable.sol";
import "./PSToken.sol";
import "./TestUtils.sol";
import "./UniswapV3PoolUtilsTest.sol";

import "../lib/LiquidityMath.sol";
import "../StratoSwapFactory.sol";
import "../StratoSwapManager.sol";
import "../StratoSwapManagerHelper.sol";

contract UniswapV3ManagerTest is Test, TestUtils {
    // ERC20Mintable weth;
    address weth;
    // ERC20Mintable usdc;
    address usdc;
    // ERC20Mintable uni;
    address uni;
    address pst;
    address donate;
    // UniswapV3Factory factory;
    address factory;
    StratoSwapPool pool;
    // address pool;
    // UniswapV3Manager manager;
    address manager;
    address managerHelper;

    bool transferInMintCallback = true;
    bool transferInSwapCallback = true;
    bytes extra;

    error ApproveError(uint256 t1, uint256 t2);

    struct LiquidityRange {
        int24 lowerTick;
        int24 upperTick;
        uint128 amount;
    }

    function setUp(
        address _weth,
        address _usdc,
        address _uni,
        address _pst,
        address _donate,
        address _factory
    ) public // address _manager
    {
        weth = _weth; //new ERC20Mintable("Ether", "ETH", 18);
        usdc = _usdc; //new ERC20Mintable("USDC", "USDC", 18);
        uni = _uni; //new ERC20Mintable("Uniswap Coin", "UNI", 18);
        pst = _pst;
        donate = _donate;
        factory = _factory; //new UniswapV3Factory();
        manager = address(new StratoSwapManager(address(factory)));
        managerHelper = address(new StratoSwapManagerHelper(address(factory)));

        extra = encodeExtra(weth, usdc, address(this));
    }

    function liquidityRange(
        uint256 lowerPrice,
        uint256 upperPrice,
        uint256 amount0,
        uint256 amount1,
        uint256 currentPrice
    ) internal pure returns (LiquidityRange memory range) {
        range = LiquidityRange({
            lowerTick: tick60(lowerPrice),
            upperTick: tick60(upperPrice),
            amount: LiquidityMath.getLiquidityForAmounts(
                sqrtP(currentPrice),
                sqrtP60(lowerPrice),
                sqrtP60(upperPrice),
                amount0,
                amount1
            )
        });
    }

    function liquidityRange(
        uint256 lowerPrice,
        uint256 upperPrice,
        uint128 amount
    ) internal pure returns (LiquidityRange memory range) {
        range = LiquidityRange({
            lowerTick: tick60(lowerPrice),
            upperTick: tick60(upperPrice),
            amount: amount
        });
    }

    function liquidityRanges(
        LiquidityRange memory range
    ) internal pure returns (LiquidityRange[] memory ranges) {
        ranges = new LiquidityRange[](1);
        ranges[0] = range;
    }

    function liquidityRanges(
        LiquidityRange memory range1,
        LiquidityRange memory range2
    ) internal pure returns (LiquidityRange[] memory ranges) {
        ranges = new LiquidityRange[](2);
        ranges[0] = range1;
        ranges[1] = range2;
    }

    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function compareBytes(
        bytes memory a,
        bytes memory b
    ) public pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    function testMintInRange() public {
        (
            IUniswapV3Manager.MintParams[] memory mints,
            uint256 poolBalance0,
            uint256 poolBalance1
        ) = setupPool(
                PoolParams({
                    wethBalance: 1 ether,
                    usdcBalance: 5000 ether,
                    currentPrice: 5000,
                    mints: mintParams(
                        mintParams(4545, 5500, 1 ether, 5000 ether)
                    ),
                    transferInMintCallback: true,
                    transferInSwapCallback: true,
                    mintLiquidity: true
                })
            );

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0.987078348444137445 ether,
            5000 ether
        );
        if (poolBalance0 != expectedAmount0) {
            setFailedStatus(true, "incorrect weth deposited amount");
            return;
        }
        if (poolBalance1 != expectedAmount1) {
            setFailedStatus(true, "incorrect usdc deposited amount");
            return;
        }

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [ERC20Mintable(weth), ERC20Mintable(usdc)],
                liquidity: liquidity(mints[0], 5000),
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                userBalances: [
                    1 ether - expectedAmount0,
                    5000 ether - expectedAmount1
                ],
                poolBalances: [expectedAmount0, expectedAmount1],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mints[0].lowerTick, mints[0].upperTick],
                    liquidity: liquidity(mints[0], 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mints[0], 5000)
                // observation: ExpectedObservationShort({
                //     index: 0,
                //     timestamp: 1,
                //     tickCumulative: 0,
                //     initialized: true
                // })
            })
        );
    }

    function testMintRangeBelow() public {
        (
            IUniswapV3Manager.MintParams[] memory mints,
            uint256 poolBalance0,
            uint256 poolBalance1
        ) = setupPool(
                PoolParams({
                    wethBalance: 1 ether,
                    usdcBalance: 5000 ether,
                    currentPrice: 5000,
                    mints: mintParams(
                        mintParams(4000, 4996, 1 ether, 5000 ether)
                    ),
                    transferInMintCallback: true,
                    transferInSwapCallback: true,
                    mintLiquidity: true
                })
            );

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0 ether,
            4999.999999999999999994 ether
        );

        // assertEq(
        //     poolBalance0,
        //     expectedAmount0,
        //     "incorrect weth deposited amount"
        // );
        if (poolBalance0 != expectedAmount0) {
            setFailedStatus(true, "incorrect weth deposited amount");
            return;
        }
        // assertEq(
        //     poolBalance1,
        //     expectedAmount1,
        //     "incorrect usdc deposited amount"
        // );
        if (poolBalance1 != expectedAmount1) {
            setFailedStatus(true, "incorrect usdc deposited amount");
            return;
        }

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [ERC20Mintable(weth), ERC20Mintable(usdc)],
                liquidity: 0,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                userBalances: [
                    1 ether - expectedAmount0,
                    5000 ether - expectedAmount1
                ],
                poolBalances: [expectedAmount0, expectedAmount1],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mints[0].lowerTick, mints[0].upperTick],
                    liquidity: liquidity(mints[0], 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mints[0], 5000)
                // observation: ExpectedObservationShort({
                //     index: 0,
                //     timestamp: 1,
                //     tickCumulative: 0,
                //     initialized: true
                // })
            })
        );
    }

    function testMintRangeAbove() public {
        (
            IUniswapV3Manager.MintParams[] memory mints,
            uint256 poolBalance0,
            uint256 poolBalance1
        ) = setupPool(
                PoolParams({
                    wethBalance: 1 ether,
                    usdcBalance: 5000 ether,
                    currentPrice: 5000,
                    mints: mintParams(
                        mintParams(5027, 6250, 1 ether, 5000 ether)
                    ),
                    transferInMintCallback: true,
                    transferInSwapCallback: true,
                    mintLiquidity: true
                })
            );

        (uint256 expectedAmount0, uint256 expectedAmount1) = (1 ether, 0);

        // assertEq(
        //     poolBalance0,
        //     expectedAmount0,
        //     "incorrect weth deposited amount"
        // );
        if (poolBalance0 != expectedAmount0) {
            setFailedStatus(true, "incorrect weth deposited amount");
            return;
        }
        // assertEq(
        //     poolBalance1,
        //     expectedAmount1,
        //     "incorrect usdc deposited amount"
        // );
        if (poolBalance1 != expectedAmount1) {
            setFailedStatus(true, "incorrect usdc deposited amount");
            return;
        }

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [ERC20Mintable(weth), ERC20Mintable(usdc)],
                liquidity: 0,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                userBalances: [
                    1 ether - expectedAmount0,
                    5000 ether - expectedAmount1
                ],
                poolBalances: [expectedAmount0, expectedAmount1],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mints[0].lowerTick, mints[0].upperTick],
                    liquidity: liquidity(mints[0], 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mints[0], 5000)
                // observation: ExpectedObservationShort({
                //     index: 0,
                //     timestamp: 1,
                //     tickCumulative: 0,
                //     initialized: true
                // })
            })
        );
    }

    //
    //          5000
    //   4545 ----|---- 5500
    // 4000 ------|------ 6250
    //
    function testMintOverlappingRanges() public {
        (IUniswapV3Manager.MintParams[] memory mints, , ) = setupPool(
            PoolParams({
                wethBalance: 3 ether,
                usdcBalance: 15000 ether,
                currentPrice: 5000,
                mints: mintParams(
                    mintParams(4545, 5500, 1 ether, 5000 ether),
                    mintParams(
                        4000,
                        6250,
                        (1 ether * 75) / 100,
                        (5000 ether * 75) / 100
                    )
                ),
                transferInMintCallback: true,
                transferInSwapCallback: true,
                mintLiquidity: true
            })
        );

        (uint256 amount0, uint256 amount1) = (
            1.733189275014643934 ether,
            8750.000000000000000000 ether
        );

        assertMany(
            ExpectedPoolAndBalances({
                pool: pool,
                tokens: [ERC20Mintable(weth), ERC20Mintable(usdc)],
                liquidity: liquidity(mints[0], 5000) +
                    liquidity(mints[1], 5000),
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                userBalances: [3 ether - amount0, 15000 ether - amount1],
                poolBalances: [amount0, amount1]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mints[0].lowerTick, mints[0].upperTick],
                    liquidity: liquidity(mints[0], 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mints[0], 5000)
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mints[1].lowerTick, mints[1].upperTick],
                    liquidity: liquidity(mints[1], 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mints[1], 5000)
            })
        );

        // assertObservation(
        //     ExpectedObservation({
        //         pool: pool,
        //         index: 0,
        //         timestamp: 1,
        //         tickCumulative: 0,
        //         initialized: true
        //     })
        // );
    }

    //
    //          5000
    //   4545 ----|---- 5500
    // 4000 ------ ------ 6250
    //      5000-1 5000+1
    function testMintPartiallyOverlappingRanges() public {
        (IUniswapV3Manager.MintParams[] memory mints, , ) = setupPool(
            PoolParams({
                wethBalance: 3 ether,
                usdcBalance: 15000 ether,
                currentPrice: 5000,
                mints: mintParams(
                    mintParams(4545, 5500, 1 ether, 5000 ether),
                    mintParams(
                        4000,
                        4996,
                        (1 ether * 75) / 100,
                        (5000 ether * 75) / 100
                    ),
                    mintParams(
                        5027,
                        6250,
                        (1 ether * 50) / 100,
                        (5000 ether * 50) / 100
                    )
                ),
                transferInMintCallback: true,
                transferInSwapCallback: true,
                mintLiquidity: true
            })
        );

        (uint256 amount0, uint256 amount1) = (
            1.487078348444137445 ether,
            8749.999999999999999994 ether
        );

        assertMany(
            ExpectedPoolAndBalances({
                pool: pool,
                tokens: [ERC20Mintable(weth), ERC20Mintable(usdc)],
                liquidity: liquidity(mints[0], 5000),
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                userBalances: [3 ether - amount0, 15000 ether - amount1],
                poolBalances: [amount0, amount1]
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mints[0].lowerTick, mints[0].upperTick],
                    liquidity: liquidity(mints[0], 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mints[0], 5000)
            })
        );

        assertMany(
            ExpectedPositionAndTicks({
                pool: pool,
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mints[1].lowerTick, mints[1].upperTick],
                    liquidity: liquidity(mints[1], 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mints[1], 5000)
            })
        );

        // assertObservation(
        //     ExpectedObservation({
        //         pool: pool,
        //         index: 0,
        //         timestamp: 1,
        //         tickCumulative: 0,
        //         initialized: true
        //     })
        // );
    }

    function testMintInvalidTickRangeLower() public {
        manager = address(new StratoSwapManager(factory));
        StratoSwapManager(manager).checkPSToken(weth);
        StratoSwapManager(manager).checkPSToken(usdc);
        pool = deployPool(
            StratoSwapFactory(factory),
            weth,
            usdc,
            3000,
            1,
            donate
        );

        // Reverted in TickMath.getSqrtRatioAtTick
        // vm.expectRevert(bytes("T"));
        try
            StratoSwapManager(manager).mint(
                IUniswapV3Manager.MintParams({
                    tokenA: weth,
                    tokenB: usdc,
                    fee: 3000,
                    lowerTick: -887273,
                    upperTick: 0,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0
                })
            )
        {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory reason) {
            // This is executed in case of a revert with a reason string
            if (!compareStrings(reason, "T"))
                setFailedStatus(
                    true,
                    "Unexpected error with unexpected reason"
                );
        } catch (bytes memory) {
            setFailedStatus(true, "Unexpected error without reason");
            // This is executed in case of a revert without a reason string
        }
    }

    function testMintInvalidTickRangeUpper() public {
        manager = address(new StratoSwapManager(factory));
        StratoSwapManager(manager).checkPSToken(weth);
        StratoSwapManager(manager).checkPSToken(usdc);
        pool = deployPool(
            StratoSwapFactory(factory),
            weth,
            usdc,
            3000,
            1,
            donate
        );

        // Reverted in TickMath.getSqrtRatioAtTick
        // vm.expectRevert(bytes("T"));
        try
            StratoSwapManager(manager).mint(
                IUniswapV3Manager.MintParams({
                    tokenA: weth,
                    tokenB: usdc,
                    fee: 3000,
                    lowerTick: 0,
                    upperTick: 887273,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0
                })
            )
        {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory reason) {
            // This is executed in case of a revert with a reason string
            if (!compareStrings(reason, "T"))
                setFailedStatus(
                    true,
                    "Unexpected error with unexpected reason"
                );
        } catch (bytes memory) {
            setFailedStatus(true, "Unexpected error without reason");
            // This is executed in case of a revert without a reason string
        }
    }

    function testMintZeroLiquidity() public {
        manager = address(new StratoSwapManager(factory));
        StratoSwapManager(manager).checkPSToken(weth);
        StratoSwapManager(manager).checkPSToken(usdc);
        pool = deployPool(
            StratoSwapFactory(factory),
            weth,
            usdc,
            3000,
            1,
            donate
        );

        // vm.expectRevert(encodeError("ZeroLiquidity()"));
        try
            StratoSwapManager(manager).mint(
                IUniswapV3Manager.MintParams({
                    tokenA: weth,
                    tokenB: usdc,
                    fee: 3000,
                    lowerTick: 0,
                    upperTick: 1,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0
                })
            )
        {
            // Handle successful pool creation
            setFailedStatus(true, "123Unexpected error");
        } catch Error(string memory) {
            // This is executed in case of a revert with a reason string
        } catch (bytes memory) {
            // setFailedStatus(true, "Unexpected error without reason");
            // This is executed in case of a revert without a reason string
            // if (compareBytes("0x10074548", reason))
                setFailedStatus(
                    true,
                    "789Unexpected error with unexpected reason"
                );
        }
    }

    function testMintInsufficientTokenBalance() public {
        (IUniswapV3Manager.MintParams[] memory mints, , ) = setupPool(
            PoolParams({
                wethBalance: 0,
                usdcBalance: 0,
                currentPrice: 5000,
                mints: mintParams(mintParams(4545, 5500, 1 ether, 5000 ether)),
                transferInMintCallback: false,
                transferInSwapCallback: true,
                mintLiquidity: false
            })
        );

        // vm.expectRevert(stdError.arithmeticError);
        try StratoSwapManager(manager).mint(mints[0]) {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory) {
            // This is executed in case of a revert with a reason string
            setFailedStatus(true, "Unexpected error with reason");
        } catch (bytes memory) {
            // This is executed in case of a revert without a reason string
        }
    }

    function testMintSlippageProtection() public {
        (uint256 amount0, uint256 amount1) = (1 ether, 5000 ether);
        manager = address(new StratoSwapManager(factory));
        StratoSwapManager(manager).checkPSToken(weth);
        StratoSwapManager(manager).checkPSToken(usdc);
        pool = deployPool(
            StratoSwapFactory(factory),
            weth,
            usdc,
            3000,
            5000,
            donate
        );

        ERC20Mintable(weth).mint(address(this), amount0);
        ERC20Mintable(usdc).mint(address(this), amount1);
        ERC20Mintable(weth).approve(manager, amount0);
        ERC20Mintable(usdc).approve(manager, amount1);

        // vm.expectRevert(
        //     encodeSlippageCheckFailed(0.987078348444137445 ether, 5000 ether)
        // );

        try
            StratoSwapManager(manager).mint(
                IUniswapV3Manager.MintParams({
                    tokenA: weth,
                    tokenB: usdc,
                    fee: 3000,
                    lowerTick: tick60(4545),
                    upperTick: tick60(5500),
                    amount0Desired: amount0,
                    amount1Desired: amount1,
                    amount0Min: amount0,
                    amount1Min: amount1
                })
            )
        {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory) {
            // This is executed in case of a revert with a reason string
            setFailedStatus(true, "Unexpected error with reason");
        } catch (bytes memory reason) {
            // This is executed in case of a revert without a reason string
            if (
                compareBytes(
                    "0xa8f6c8d00000000000000000000000000000000000000000000000000db2ce87347df7e500000000000000000000000000000000000000000000010f0cf064dd59200000",
                    reason
                )
            ) setFailedStatus(true, "Unexpected error with unexpected reason");
        }

        StratoSwapManager(manager).mint(
            IUniswapV3Manager.MintParams({
                tokenA: weth,
                tokenB: usdc,
                fee: 3000,
                lowerTick: tick60(4545),
                upperTick: tick60(5500),
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: (amount0 * 98) / 100,
                amount1Min: (amount1 * 98) / 100
            })
        );
    }

    function testSwapBuyMultipool() public {
        // Deploy WETH/USDC pool
        (
            IUniswapV3Manager.MintParams[] memory mints,
            uint256 poolBalance0,
            uint256 poolBalance1
        ) = setupPool(
                PoolParams({
                    wethBalance: 1 ether,
                    usdcBalance: 5000 ether,
                    currentPrice: 5000,
                    mints: mintParams(
                        mintParams(4545, 5500, 1 ether, 5000 ether)
                    ),
                    transferInMintCallback: true,
                    transferInSwapCallback: true,
                    mintLiquidity: true
                })
            );

        // Deploy WETH/UNI pool
        (
            StratoSwapPool wethUNI,
            IUniswapV3Manager.MintParams[] memory wethUNIMints,
            uint256 wethUNIBalance0,
            uint256 wethUNIBalance1
        ) = setupPool(
                PoolParamsFull({
                    token0: ERC20Mintable(weth),
                    token1: ERC20Mintable(uni),
                    token0Balance: 10 ether,
                    token1Balance: 100 ether,
                    currentPrice: 10,
                    mints: mintParams(
                        mintParams(
                            ERC20Mintable(weth),
                            ERC20Mintable(uni),
                            7,
                            13,
                            10 ether,
                            100 ether
                        )
                    ),
                    transferInMintCallback: true,
                    transferInSwapCallback: true,
                    mintLiquidity: true
                })
            );

        uint256 swapAmount = 2.5 ether;
        ERC20Mintable(uni).mint(address(this), swapAmount);
        ERC20Mintable(uni).approve(manager, swapAmount);

        bytes memory path = bytes.concat(
            bytes20(uni),
            bytes3(uint24(3000)),
            bytes20(weth),
            bytes3(uint24(3000)),
            bytes20(usdc)
        );

        uint256[] memory userBalances = new uint256[](3);
        (userBalances[0], userBalances[1], userBalances[2]) = (
            ERC20Mintable(weth).balanceOf(address(this)),
            ERC20Mintable(usdc).balanceOf(address(this)),
            ERC20Mintable(uni).balanceOf(address(this))
        );

        uint256 amountOut = StratoSwapManager(manager).swap(
            IUniswapV3Manager.SwapParams({
                path: path,
                recipient: address(this),
                amountIn: swapAmount,
                minAmountOut: 0
            })
        );

        // assertEq(amountOut, 1223.599499987434631189 ether, "invalid USDC out");
        if (amountOut != 1223.599499987434631189 ether) {
            setFailedStatus(true, "invalid USDC out");
            return;
        }

        IUniswapV3Manager.MintParams memory mint = mints[0];
        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [ERC20Mintable(weth), ERC20Mintable(usdc)],
                liquidity: liquidity(mint, 5000),
                sqrtPriceX96: 5539583677789714904297843583839, // 4888.719128166855
                tick: 84951,
                fees: [
                    uint256(163879779853250804931705964313699), // 0.000000481599388579
                    0
                ],
                userBalances: [userBalances[0], userBalances[1] + amountOut],
                poolBalances: [
                    poolBalance0 + 0.248234183855004779 ether, // initial + 2.5 UNI sold for ETH
                    poolBalance1 - amountOut
                ],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mint.lowerTick, mint.upperTick],
                    liquidity: liquidity(mint, 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mint, 5000)
                // observation: ExpectedObservationShort({
                //     index: 0,
                //     timestamp: 1,
                //     tickCumulative: 0,
                //     initialized: true
                // })
            })
        );

        mint = wethUNIMints[0];
        assertMany(
            ExpectedMany({
                pool: wethUNI,
                tokens: [ERC20Mintable(weth), ERC20Mintable(uni)],
                liquidity: liquidity(mint, 10),
                sqrtPriceX96: 251566706235579008314845847774, // 10.082010831439806
                tick: 23108,
                fees: [
                    uint256(0),
                    13250097234547358482322170106940574 // 0.000038938536117641
                ],
                userBalances: [userBalances[0], userBalances[2] - swapAmount],
                poolBalances: [
                    wethUNIBalance0 - 0.248234183855004779 ether,
                    wethUNIBalance1 + swapAmount
                ],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mint.lowerTick, mint.upperTick],
                    liquidity: liquidity(mint, 10),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mint, 10)
                // observation: ExpectedObservationShort({
                //     index: 0,
                //     timestamp: 1,
                //     tickCumulative: 0,
                //     initialized: true
                // })
            })
        );
    }

    function testSwapBuyEthNotEnoughLiquidity() public {
        setupPool(
            PoolParams({
                wethBalance: 1 ether,
                usdcBalance: 5000 ether,
                currentPrice: 5000,
                mints: mintParams(mintParams(4545, 5500, 1 ether, 5000 ether)),
                transferInMintCallback: true,
                transferInSwapCallback: true,
                mintLiquidity: true
            })
        );

        uint256 swapAmount = 5300 ether;
        ERC20Mintable(usdc).mint(address(this), swapAmount);
        ERC20Mintable(usdc).approve(address(this), swapAmount);

        // vm.expectRevert(encodeError("NotEnoughLiquidity()"));
        try
            StratoSwapManager(manager).swapSingle(
                IUniswapV3Manager.SwapSingleParams({
                    tokenIn: weth,
                    tokenOut: usdc,
                    fee: 3000,
                    amountIn: swapAmount
                })
            )
        {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory) {
            // This is executed in case of a revert with a reason string
            setFailedStatus(true, "Unexpected error with reason");
        } catch (bytes memory reason) {
            // This is executed in case of a revert without a reason string
            if (compareBytes("0x4323a555", reason))
                setFailedStatus(
                    true,
                    "Unexpected error with unexpected reason"
                );
        }
    }

    function testSwapBuyUSDCNotEnoughLiquidity() public {
        setupPool(
            PoolParams({
                wethBalance: 1 ether,
                usdcBalance: 5000 ether,
                currentPrice: 5000,
                mints: mintParams(mintParams(4545, 5500, 1 ether, 5000 ether)),
                transferInMintCallback: true,
                transferInSwapCallback: true,
                mintLiquidity: true
            })
        );

        uint256 swapAmount = 1.1 ether;
        ERC20Mintable(weth).mint(address(this), swapAmount);
        ERC20Mintable(weth).approve(address(this), swapAmount);

        // vm.expectRevert(encodeError("NotEnoughLiquidity()"));
        try
            StratoSwapManager(manager).swapSingle(
                IUniswapV3Manager.SwapSingleParams({
                    tokenIn: weth,
                    tokenOut: usdc,
                    fee: 3000,
                    amountIn: swapAmount
                })
            )
        {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory) {
            // This is executed in case of a revert with a reason string
            setFailedStatus(true, "Unexpected error with reason");
        } catch (bytes memory reason) {
            // This is executed in case of a revert without a reason string
            if (compareBytes("0x4323a555", reason))
                setFailedStatus(
                    true,
                    "Unexpected error with unexpected reason"
                );
        }
    }

    function testMintRangeBelowWithPST() public {
        (
            StratoSwapPool pool1,
            IUniswapV3Manager.MintParams[] memory mints,
            uint256 poolBalance0,
            uint256 poolBalance1
        ) = setupPool(
                PoolParamsFull({
                    token0: ERC20Mintable(weth),
                    token1: ERC20Mintable(pst),
                    token0Balance: 1 ether,
                    token1Balance: 5000 ether,
                    currentPrice: 5000,
                    mints: mintParams(
                        mintParams(
                            ERC20Mintable(weth),
                            ERC20Mintable(pst),
                            4000,
                            4996,
                            1 ether,
                            5000 ether
                        )
                    ),
                    transferInMintCallback: true,
                    transferInSwapCallback: true,
                    mintLiquidity: true
                })
            );

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0 ether,
            4999.999999999999999994 ether
        );

        if (poolBalance0 != expectedAmount0) {
            setFailedStatus(true, "incorrect weth deposited amount");
            return;
        }
        if (poolBalance1 != expectedAmount1) {
            setFailedStatus(true, "incorrect usdc deposited amount");
            return;
        }

        assertMany(
            ExpectedMany({
                pool: pool1,
                tokens: [ERC20Mintable(weth), ERC20Mintable(pst)],
                liquidity: 0,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                userBalances: [
                    1 ether - expectedAmount0,
                    0.000000000000000007 ether
                ],
                poolBalances: [expectedAmount0, expectedAmount1],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mints[0].lowerTick, mints[0].upperTick],
                    liquidity: liquidity(mints[0], 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mints[0], 5000)
                // observation: ExpectedObservationShort({
                //     index: 0,
                //     timestamp: 1,
                //     tickCumulative: 0,
                //     initialized: true
                // })
            })
        );
    }

    function testMintRangeAboveWithPST() public {
        (
            StratoSwapPool pool1,
            IUniswapV3Manager.MintParams[] memory mints,
            uint256 poolBalance0,
            uint256 poolBalance1
        ) = setupPool(
                PoolParamsFull({
                    token0: ERC20Mintable(weth),
                    token1: ERC20Mintable(pst),
                    token0Balance: 1 ether,
                    token1Balance: 5000 ether,
                    currentPrice: 5000,
                    mints: mintParams(
                        mintParams(
                            ERC20Mintable(weth),
                            ERC20Mintable(pst),
                            5027,
                            6250,
                            1 ether,
                            5000 ether
                        )
                    ),
                    transferInMintCallback: true,
                    transferInSwapCallback: true,
                    mintLiquidity: true
                })
            );

        (uint256 expectedAmount0, uint256 expectedAmount1) = (1 ether, 0);

        if (poolBalance0 != expectedAmount0) {
            setFailedStatus(true, "incorrect weth deposited amount");
            return;
        }
        if (poolBalance1 != expectedAmount1) {
            setFailedStatus(true, "incorrect usdc deposited amount");
            return;
        }

        assertMany(
            ExpectedMany({
                pool: pool1,
                tokens: [ERC20Mintable(weth), ERC20Mintable(pst)],
                liquidity: 0,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                userBalances: [
                    1 ether - expectedAmount0,
                    5005.005005005005005005 ether - expectedAmount1
                ],
                poolBalances: [expectedAmount0, expectedAmount1],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [mints[0].lowerTick, mints[0].upperTick],
                    liquidity: liquidity(mints[0], 5000),
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [uint128(0), 0]
                }),
                ticks: mintParamsToTicks(mints[0], 5000)
            })
        );
    }

    function testMintInvalidTickRangeLowerWithPST() public {
        manager = address(new StratoSwapManager(factory));
        StratoSwapManager(manager).checkPSToken(weth);
        StratoSwapManager(manager).checkPSToken(pst);
        pool = deployPool(
            StratoSwapFactory(factory),
            weth,
            pst,
            3000,
            1,
            donate
        );

        // Reverted in TickMath.getSqrtRatioAtTick
        // vm.expectRevert(bytes("T"));
        try
            StratoSwapManager(manager).mint(
                IUniswapV3Manager.MintParams({
                    tokenA: weth,
                    tokenB: pst,
                    fee: 3000,
                    lowerTick: -887273,
                    upperTick: 0,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0
                })
            )
        {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory reason) {
            // This is executed in case of a revert with a reason string
            if (!compareStrings(reason, "T"))
                setFailedStatus(
                    true,
                    "Unexpected error with unexpected reason"
                );
        } catch (bytes memory) {
            setFailedStatus(true, "Unexpected error without reason");
            // This is executed in case of a revert without a reason string
        }
    }

    function testMintInvalidTickRangeUpperWithPST() public {
        manager = address(new StratoSwapManager(factory));
        StratoSwapManager(manager).checkPSToken(weth);
        StratoSwapManager(manager).checkPSToken(pst);
        pool = deployPool(
            StratoSwapFactory(factory),
            weth,
            pst,
            3000,
            1,
            donate
        );

        // Reverted in TickMath.getSqrtRatioAtTick
        // vm.expectRevert(bytes("T"));
        try
            StratoSwapManager(manager).mint(
                IUniswapV3Manager.MintParams({
                    tokenA: weth,
                    tokenB: pst,
                    fee: 3000,
                    lowerTick: 0,
                    upperTick: 887273,
                    amount0Desired: 0,
                    amount1Desired: 0,
                    amount0Min: 0,
                    amount1Min: 0
                })
            )
        {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory reason) {
            // This is executed in case of a revert with a reason string
            if (!compareStrings(reason, "T"))
                setFailedStatus(
                    true,
                    "Unexpected error with unexpected reason"
                );
        } catch (bytes memory) {
            setFailedStatus(true, "Unexpected error without reason");
            // This is executed in case of a revert without a reason string
        }
    }

    function testBurn() public {
        setupPool(
            PoolParams({
                wethBalance: 1 ether,
                usdcBalance: 5000 ether,
                currentPrice: 5000,
                mints: mintParams(mintParams(4545, 5500, 1 ether, 5000 ether)),
                transferInMintCallback: true,
                transferInSwapCallback: true,
                mintLiquidity: true
            })
        );

        (uint256 expectedAmount0, uint256 expectedAmount1) = (
            0.987078348444137444 ether,
            4999.999999999999999999 ether
        );

        LiquidityRange memory liquidity1 = liquidityRange(
            4545,
            5500,
            1 ether,
            5000 ether,
            5000
        );
        (uint256 burnAmount0, uint256 burnAmount1) = StratoSwapManager(manager)
            .burn(
                IUniswapV3Manager.BurnParams(
                    weth,
                    usdc,
                    3000,
                    liquidity1.lowerTick,
                    liquidity1.upperTick,
                    liquidity1.amount
                )
            );

        // assertEq(burnAmount0, expectedAmount0, "incorrect weth burned amount");
        if (burnAmount0 != expectedAmount0) {
            setFailedStatus(true, "incorrect weth burned amount");
            return;
        }
        // assertEq(burnAmount1, expectedAmount1, "incorrect usdc burned amount");
        if (burnAmount1 != expectedAmount1) {
            setFailedStatus(true, "incorrect usdc burned amount");
            return;
        }

        assertMany(
            ExpectedMany({
                pool: pool,
                tokens: [ERC20Mintable(weth), ERC20Mintable(usdc)],
                liquidity: 0,
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000),
                fees: [uint256(0), 0],
                userBalances: [
                    1 ether - expectedAmount0 - 1,
                    5000 ether - expectedAmount1 - 1
                ],
                poolBalances: [expectedAmount0 + 1, expectedAmount1 + 1],
                position: ExpectedPositionShort({
                    owner: address(this),
                    ticks: [liquidity1.lowerTick, liquidity1.upperTick],
                    liquidity: 0,
                    feeGrowth: [uint256(0), 0],
                    tokensOwed: [
                        uint128(expectedAmount0),
                        uint128(expectedAmount1)
                    ]
                }),
                ticks: [
                    ExpectedTickShort({
                        tick: liquidity1.lowerTick,
                        initialized: true, // TODO: fix, must be false
                        liquidityGross: 0,
                        liquidityNet: 0
                    }),
                    ExpectedTickShort({
                        tick: liquidity1.upperTick,
                        initialized: true, // TODO: fix, must be false
                        liquidityGross: 0,
                        liquidityNet: 0
                    })
                ]
                // observation: ExpectedObservationShort({
                //     index: 0,
                //     timestamp: 1,
                //     tickCumulative: 0,
                //     initialized: true
                // })
            })
        );
    }

    function testSingleSwapAndCollectFee() public {
        setupPool(
            PoolParams({
                wethBalance: 1 ether,
                usdcBalance: 5000 ether,
                currentPrice: 5000,
                mints: mintParams(mintParams(4545, 5500, 1 ether, 5000 ether)),
                transferInMintCallback: true,
                transferInSwapCallback: true,
                mintLiquidity: true
            })
        );

        (int24 expectedLowerTick, int24 expecteduUpperTick) = (84240, 86100);
        uint128 expectedLiquidity = 1546311247949719370887;
        uint128 realLiquidity = StratoSwapManagerHelper(managerHelper).getLiquidity(weth, usdc, 3000, address(this), expectedLowerTick, expecteduUpperTick);
        if(realLiquidity != expectedLiquidity) revert ("Liquidity isn't correct");

        uint256 swapAmount = 0.5 ether;
        ERC20Mintable(weth).mint(address(this), swapAmount);
        ERC20Mintable(weth).approve(manager, swapAmount);

        StratoSwapManager(manager).swapSingle(
            IUniswapV3Manager.SwapSingleParams({
                tokenIn: weth,
                tokenOut: usdc,
                fee: 3000,
                amountIn: swapAmount
            })
        );

        (uint256 expectedSwapResult1, uint256 expectedSwapResult2) = (12921651555862555, 2436948023397513049735);
        if(expectedSwapResult1 != IERC20(weth).balanceOf(address(this))) revert ("Unexpected Swap Result with weth");
        if(expectedSwapResult2 != IERC20(usdc).balanceOf(address(this))) revert ("Unexpected Swap Result with usdc");

        (uint256 tokensOwed0, uint256 tokensOwed1) = StratoSwapManagerHelper(managerHelper).getAccumulatedFeeAmount(address(this), weth, usdc, 3000, expectedLowerTick, expecteduUpperTick);
        (uint256 expectedTokensOwed0, uint256 expectedTokensOwed1) = (1499999999999999, 0);
        if(expectedTokensOwed0 != tokensOwed0) revert ("Unexpected TokensOwed0");
        if(expectedTokensOwed1 != tokensOwed1) revert ("Unexpected TokensOwed1");

        StratoSwapManager(manager).collect(IUniswapV3Manager.CollectParams({
            tokenA: weth,
            tokenB: usdc,
            fee: 3000,
            recipient: address(this),
            lowerTick: expectedLowerTick,
            upperTick: expecteduUpperTick,
            amount0Desired: 10 ether,
            amount1Desired: 5000 ether
        }));

        (expectedSwapResult1, expectedSwapResult2) = (14406651555862554, 2436948023397513049735);
        if(expectedSwapResult1 != IERC20(weth).balanceOf(address(this))) revert ("Unexpected Swap Result with weth");
        if(expectedSwapResult2 != IERC20(usdc).balanceOf(address(this))) revert ("Unexpected Swap Result with usdc");
        
        (tokensOwed0, tokensOwed1) = StratoSwapManagerHelper(managerHelper).getOwnerAccumulatedFeeAmount(weth, usdc, 3000);
        (expectedTokensOwed0, expectedTokensOwed1) = (15000000000000, 0);
        if(expectedTokensOwed0 != tokensOwed0) revert ("Unexpected TokensOwed0");
        if(expectedTokensOwed1 != tokensOwed1) revert ("Unexpected TokensOwed1");
    }

    function testMultiSwapAndCollectFee() public {
        setupPool(
            PoolParams({
                wethBalance: 1 ether,
                usdcBalance: 5000 ether,
                currentPrice: 5000,
                mints: mintParams(mintParams(4545, 5500, 1 ether, 5000 ether)),
                transferInMintCallback: true,
                transferInSwapCallback: true,
                mintLiquidity: true
            })
        );

        (int24 expectedLowerTick, int24 expecteduUpperTick) = (84240, 86100);
        uint256 swapAmount = 0.5 ether;
        ERC20Mintable(weth).mint(address(this), swapAmount);
        ERC20Mintable(weth).approve(manager, swapAmount);

        StratoSwapManager(manager).swapSingle(
            IUniswapV3Manager.SwapSingleParams({
                tokenIn: weth,
                tokenOut: usdc,
                fee: 3000,
                amountIn: swapAmount
            })
        );

        swapAmount = 2000 ether;
        ERC20Mintable(usdc).approve(manager, swapAmount);

        StratoSwapManager(manager).swapSingle(
            IUniswapV3Manager.SwapSingleParams({
                tokenIn: usdc,
                tokenOut: weth,
                fee: 3000,
                amountIn: swapAmount
            })
        );

        (uint256 expectedSwapResult1, uint256 expectedSwapResult2) = (422471703494836678, 436948023397513049735);
        if(expectedSwapResult1 != IERC20(weth).balanceOf(address(this))) revert ("Unexpected Swap Result with weth");
        if(expectedSwapResult2 != IERC20(usdc).balanceOf(address(this))) revert ("Unexpected Swap Result with usdc");
        
        (uint256 tokensOwed0, uint256 tokensOwed1) = StratoSwapManagerHelper(managerHelper).getAccumulatedFeeAmount(address(this), weth, usdc, 3000, expectedLowerTick, expecteduUpperTick);
        (uint256 expectedTokensOwed0, uint256 expectedTokensOwed1) = (1499999999999999, 5999999999999999999);
        if(expectedTokensOwed0 != tokensOwed0) revert ("Unexpected TokensOwed0");
        if(expectedTokensOwed1 != tokensOwed1) revert ("Unexpected TokensOwed1");

        StratoSwapManager(manager).collect(IUniswapV3Manager.CollectParams({
            tokenA: weth,
            tokenB: usdc,
            fee: 3000,
            recipient: address(this),
            lowerTick: expectedLowerTick,
            upperTick: expecteduUpperTick,
            amount0Desired: 10 ether,
            amount1Desired: 5000 ether
        }));

        (expectedSwapResult1, expectedSwapResult2) = (423956703494836677, 442888023397513049734);
        if(expectedSwapResult1 != IERC20(weth).balanceOf(address(this))) revert ("Unexpected Swap Result with weth");
        if(expectedSwapResult2 != IERC20(usdc).balanceOf(address(this))) revert ("Unexpected Swap Result with usdc");

        (tokensOwed0, tokensOwed1) = StratoSwapManagerHelper(managerHelper).getOwnerAccumulatedFeeAmount(weth, usdc, 3000);
        (expectedTokensOwed0, expectedTokensOwed1) = (15000000000000, 60000000000000000);
        if(expectedTokensOwed0 != tokensOwed0) revert ("Unexpected TokensOwed0");
        if(expectedTokensOwed1 != tokensOwed1) revert ("Unexpected TokensOwed1");
    }

    function testDonate() public {
        setupPool(
            PoolParams({
                wethBalance: 3 ether,
                usdcBalance: 15000 ether,
                currentPrice: 5000,
                mints: mintParams(
                    mintParams(4545, 5500, 1 ether, 5000 ether),
                    mintParams(
                        4000,
                        6250,
                        (1 ether * 75) / 100,
                        (5000 ether * 75) / 100
                    )
                ),
                transferInMintCallback: true,
                transferInSwapCallback: true,
                mintLiquidity: true
            })
        );

        uint256 donateAmount = 100 ether;
        ERC20Mintable(donate).mint(address(this), donateAmount);
        ERC20Mintable(donate).approve(managerHelper, donateAmount);
        StratoSwapManagerHelper(managerHelper).donate(weth, usdc, 3000, donateAmount);

        uint256 expectedDonateAmount = StratoSwapManagerHelper(managerHelper).getDonatedAmount(address(this), weth, usdc, 3000);
        if(expectedDonateAmount != 100 ether) revert ("Unexpected donation amount");
    }

    function testProject() public {
        StratoSwapManager(manager).createPool(IUniswapV3Manager.CreatePoolParams({
            tokenA: pst,
            tokenB: uni,
            fee: 3000,
            currentPrice: (10 ** 36),
            tokenDonate: donate
        }));

        uint256 pstAmount = 2 ether;
        ERC20Mintable(pst).mint(address(this), pstAmount);
        ERC20Mintable(pst).approve(manager, pstAmount);

        uint256 uniAmount = (10 ** 36);
        ERC20Mintable(uni).mint(address(this), uniAmount);
        ERC20Mintable(uni).approve(manager, uniAmount);

        // uint256 balance1 = ERC20Mintable(pst).balanceOf(address(this));
        // uint256 balance2 = ERC20Mintable(uni).balanceOf(address(this));
        // revert MintableError(balance1, balance2);
        // (uint160 expectedSqrtPriceX96,
        //     int24 expectedStandardTick,
        //     int24 expectedStandatdLowTick,
        //     int24 expectedStandardUpTick) = StratoSwapManagerHelper(managerHelper).getStandardSlot0(pst, uni, 3000);
        // revert MintabError(expectedSqrtPriceX96, expectedStandardTick, expectedStandatdLowTick, expectedStandardUpTick);
        StratoSwapManager(manager).mint(IUniswapV3Manager.MintParams({
            tokenA: pst,
            tokenB: uni,
            fee: 3000,
            lowerTick: 370740,
            upperTick: 463380,
            amount0Desired: 1 ether,
            amount1Desired: (10 ** 36),
            amount0Min: 0,
            amount1Min: 0
        }));
        // bool temp1 = StratoSwapManager(manager).checkPSToken(weth);
        // if(temp1 == true) revert ("ERROR");
        // bool temp2 = StratoSwapManager(manager).checkPSToken(pst);
        // if(temp2 == false) revert ("ERROR");
    }
// 1000000000000000000
// 0972111896833302284040158782402941358
    ////////////////////////////////////////////////////////////////////////////
    //
    // INTERNAL
    //
    ////////////////////////////////////////////////////////////////////////////
    struct PoolParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        uint256 currentPrice;
        IUniswapV3Manager.MintParams[] mints;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiquidity;
    }

    struct PoolParamsFull {
        ERC20Mintable token0;
        ERC20Mintable token1;
        uint256 token0Balance;
        uint256 token1Balance;
        uint256 currentPrice;
        IUniswapV3Manager.MintParams[] mints;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiquidity;
    }

    function mintParams(
        ERC20Mintable token0,
        ERC20Mintable token1,
        uint256 lowerPrice,
        uint256 upperPrice,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (IUniswapV3Manager.MintParams memory params) {
        params = mintParams(
            address(token0),
            address(token1),
            lowerPrice,
            upperPrice,
            amount0,
            amount1
        );
    }

    function mintParams(
        uint256 lowerPrice,
        uint256 upperPrice,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (IUniswapV3Manager.MintParams memory params) {
        params = mintParams(
            ERC20Mintable(weth),
            ERC20Mintable(usdc),
            lowerPrice,
            upperPrice,
            amount0,
            amount1
        );
    }

    function mintParams(
        IUniswapV3Manager.MintParams memory mint
    ) internal pure returns (IUniswapV3Manager.MintParams[] memory mints) {
        mints = new IUniswapV3Manager.MintParams[](1);
        mints[0] = mint;
    }

    function mintParams(
        IUniswapV3Manager.MintParams memory mint1,
        IUniswapV3Manager.MintParams memory mint2
    ) internal pure returns (IUniswapV3Manager.MintParams[] memory mints) {
        mints = new IUniswapV3Manager.MintParams[](2);
        mints[0] = mint1;
        mints[1] = mint2;
    }

    function mintParams(
        IUniswapV3Manager.MintParams memory mint1,
        IUniswapV3Manager.MintParams memory mint2,
        IUniswapV3Manager.MintParams memory mint3
    ) internal pure returns (IUniswapV3Manager.MintParams[] memory mints) {
        mints = new IUniswapV3Manager.MintParams[](3);
        mints[0] = mint1;
        mints[1] = mint2;
        mints[2] = mint3;
    }

    function mintParamsToTicks(
        IUniswapV3Manager.MintParams memory mint,
        uint256 currentPrice
    ) internal pure returns (ExpectedTickShort[2] memory ticks) {
        uint128 liq = liquidity(mint, currentPrice);

        ticks[0] = ExpectedTickShort({
            tick: mint.lowerTick,
            initialized: true,
            liquidityGross: liq,
            liquidityNet: int128(liq)
        });
        ticks[1] = ExpectedTickShort({
            tick: mint.upperTick,
            initialized: true,
            liquidityGross: liq,
            liquidityNet: -int128(liq)
        });
    }

    function liquidity(
        IUniswapV3Manager.MintParams memory params,
        uint256 currentPrice
    ) internal pure returns (uint128 liquidity_) {
        liquidity_ = LiquidityMath.getLiquidityForAmounts(
            sqrtP(currentPrice),
            sqrtP60FromTick(params.lowerTick),
            sqrtP60FromTick(params.upperTick),
            params.amount0Desired,
            params.amount1Desired
        );
    }

    error MintabaError(address);

    function setupPool(
        PoolParamsFull memory params
    )
        internal
        returns (
            StratoSwapPool pool_,
            IUniswapV3Manager.MintParams[] memory mints_,
            uint256 poolBalance0,
            uint256 poolBalance1
        )
    {
        uint256 mintBalance0 = params.token0Balance;
        uint256 mintBalance1 = params.token1Balance;

        if (address(params.token0) == pst) {
            mintBalance0 =
                mintBalance0 +
                PSToken(address(params.token0)).transferFee(
                    params.token0Balance
                );
        }
        if (address(params.token1) == pst) {
            mintBalance1 =
                mintBalance1 +
                PSToken(address(params.token1)).transferFee(
                    params.token1Balance
                );
        }
        params.token0.mint(address(this), mintBalance0);
        params.token1.mint(address(this), mintBalance1);

        StratoSwapManager(manager).checkPSToken(address(params.token0));
        StratoSwapManager(manager).checkPSToken(address(params.token1));
        pool_ = deployPool(
            StratoSwapFactory(factory),
            address(params.token0),
            address(params.token1),
            3000,
            params.currentPrice,
            donate
        );

        if (params.mintLiquidity) {
            params.token0.approve(manager, mintBalance0);
            params.token1.approve(manager, mintBalance1);

            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;
            for (uint256 i = 0; i < params.mints.length; i++) {
                (poolBalance0Tmp, poolBalance1Tmp) = StratoSwapManager(manager)
                    .mint(params.mints[i]);
                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }
            // revert MintabaError(
            //     mintBalance1,
            //     params.token1.balanceOf(address(pool_))
            // );
        }

        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;
        mints_ = params.mints;
    }

    function setupPool(
        PoolParams memory params
    )
        internal
        returns (
            IUniswapV3Manager.MintParams[] memory mints_,
            uint256 poolBalance0,
            uint256 poolBalance1
        )
    {
        (pool, mints_, poolBalance0, poolBalance1) = setupPool(
            PoolParamsFull({
                token0: ERC20Mintable(weth),
                token1: ERC20Mintable(usdc),
                token0Balance: params.wethBalance,
                token1Balance: params.usdcBalance,
                currentPrice: params.currentPrice,
                mints: params.mints,
                transferInMintCallback: params.transferInMintCallback,
                transferInSwapCallback: params.transferInSwapCallback,
                mintLiquidity: params.mintLiquidity
            })
        );
    }
}
