// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "../StratoSwapFactory.sol";
import "../StratoSwapManager.sol";
import "../StratoSwapPool.sol";
import "../StratoSwapQuoter.sol";
import "./ERC20Mintable.sol";
import "./TestUtils.sol";

contract UniswapV3QuoterTest is Test, TestUtils {
    // ERC20Mintable weth;
    // ERC20Mintable usdc;
    // ERC20Mintable uni;
    // UniswapV3Factory factory;
    // UniswapV3Pool wethUSDC;
    // UniswapV3Pool wethUNI;
    // UniswapV3Manager manager;
    // UniswapV3Quoter quoter;
    address weth;
    address usdc;
    address uni;
    address donate;
    address factory;
    address wethUSDC;
    address wethUNI;
    address manager;
    address quoter;

    event logError();

    function setUp(
        address _weth,
        address _usdc,
        address _uni,
        address _donate,
        address _factory
    ) public {
        usdc = _usdc; //new ERC20Mintable("USDC", "USDC", 18);
        weth = _weth; //new ERC20Mintable("Ether", "ETH", 18);
        uni = _uni; //new ERC20Mintable("Uniswap Coin", "UNI", 18);
        donate = _donate;
        factory = _factory; //new UniswapV3Factory();
    }

    function processing() public {
        uint256 wethBalance = 100 ether;
        uint256 usdcBalance = 1000000 ether;
        uint256 uniBalance = 1000 ether;

        ERC20Mintable(weth).mint(address(this), wethBalance);
        ERC20Mintable(usdc).mint(address(this), usdcBalance);
        ERC20Mintable(uni).mint(address(this), uniBalance);

        // Should be corrected
        manager = address(new StratoSwapManager(factory));
        StratoSwapManager(manager).checkPSToken(weth);
        StratoSwapManager(manager).checkPSToken(usdc);
        StratoSwapManager(manager).checkPSToken(uni);

        wethUSDC = address(
            deployPool(
                StratoSwapFactory(factory),
                weth,
                usdc,
                3000,
                5000,
                donate
            )
        );
        wethUNI = address(
            deployPool(StratoSwapFactory(factory), weth, uni, 3000, 10, donate)
        );

        ERC20Mintable(weth).approve(manager, wethBalance);
        ERC20Mintable(usdc).approve(manager, usdcBalance);
        ERC20Mintable(uni).approve(manager, uniBalance);

        StratoSwapManager(manager).mint(
            IUniswapV3Manager.MintParams({
                tokenA: weth,
                tokenB: usdc,
                fee: 3000,
                lowerTick: tick60(4545),
                upperTick: tick60(5500),
                amount0Desired: 1 ether,
                amount1Desired: 5000 ether,
                amount0Min: 0,
                amount1Min: 0
            })
        );

        StratoSwapManager(manager).mint(
            IUniswapV3Manager.MintParams({
                tokenA: weth,
                tokenB: uni,
                fee: 3000,
                lowerTick: tick60(7),
                upperTick: tick60(13),
                amount0Desired: 10 ether,
                amount1Desired: 100 ether,
                amount0Min: 0,
                amount1Min: 0
            })
        );

        quoter = address(new StratoSwapQuoter(factory));
    }

    function testQuoteUSDCforETH() public {
        (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            int24 tickAfter
        ) = StratoSwapQuoter(quoter).quoteSingle(
                StratoSwapQuoter.QuoteSingleParams({
                    tokenIn: weth,
                    tokenOut: usdc,
                    fee: 3000,
                    amountIn: 0.01337 ether,
                    sqrtPriceLimitX96: sqrtP(4993)
                })
            );

        assertEq(amountOut, 66.608848079558229697 ether, "invalid amountOut");
        assertEq(
            sqrtPriceX96After,
            5598864267980327381293641469695, // 4993.909994249256
            "invalid sqrtPriceX96After"
        );
        assertEq(tickAfter, 85164, "invalid tickAFter");
    }

    function testQuoteETHforUSDC() public {
        (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            int24 tickAfter
        ) = StratoSwapQuoter(quoter).quoteSingle(
                StratoSwapQuoter.QuoteSingleParams({
                    tokenIn: usdc,
                    tokenOut: weth,
                    fee: 3000,
                    amountIn: 42 ether,
                    sqrtPriceLimitX96: sqrtP(5005)
                })
            );

        assertEq(amountOut, 0.008371593947078467 ether, "invalid amountOut");
        assertEq(
            sqrtPriceX96After,
            5604422590555458105735383351329, // 5003.830413717752
            "invalid sqrtPriceX96After"
        );
        assertEq(tickAfter, 85183, "invalid tickAFter");
    }

    /**
     * UNI -> ETH -> USDC
     *    10/1   1/5000
     */
    function testQuoteUNIforUSDCviaETH() public {
        bytes memory path = bytes.concat(
            bytes20(uni),
            bytes3(uint24(3000)),
            bytes20(weth),
            bytes3(uint24(3000)),
            bytes20(usdc)
        );
        (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            int24[] memory tickAfterList
        ) = StratoSwapQuoter(quoter).quote(path, 3 ether);

        assertEq(amountOut, 1463.863228593034635225 ether, "invalid amountOut");
        assertEq(
            sqrtPriceX96AfterList[0],
            251771757807685223741030010328, // 10.098453187753986
            "invalid sqrtPriceX96After"
        );
        assertEq(
            sqrtPriceX96AfterList[1],
            5527273314166940201896143730186, // 4867.015316523305
            "invalid sqrtPriceX96After"
        );
        assertEq(tickAfterList[0], 23124, "invalid tickAFter");
        assertEq(tickAfterList[1], 84906, "invalid tickAFter");
    }

    /**
     * UNI -> ETH -> USDC
     *    10/1   1/5000
     */
    function testQuoteAndSwapUNIforUSDCviaETH() public {
        uint256 amountIn = 3 ether;
        bytes memory path = bytes.concat(
            bytes20(uni),
            bytes3(uint24(3000)),
            bytes20(weth),
            bytes3(uint24(3000)),
            bytes20(usdc)
        );
        (uint256 amountOut, , ) = StratoSwapQuoter(quoter).quote(
            path,
            amountIn
        );

        uint256 amountOutActual = StratoSwapManager(manager).swap(
            IUniswapV3Manager.SwapParams({
                path: path,
                recipient: address(this),
                amountIn: amountIn,
                minAmountOut: amountOut
            })
        );

        assertEq(amountOutActual, amountOut, "invalid amount1Delta");
    }
}
