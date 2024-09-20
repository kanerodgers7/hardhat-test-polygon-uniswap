// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "../UniswapV3Factory.sol";
import "../UniswapV3Manager.sol";
import "../UniswapV3Pool.sol";
import "../UniswapV3Quoter.sol";
import "./ERC20Mintable.sol";
import "./TestUtils.sol";

contract UniswapV3QuoterTest is Test, TestUtils {
    address weth;
    address usdc;
    address uni;
    address factory;
    address wethUSDC;
    address wethUNI;
    address manager;
    address quoter;
    address temp;

    function setUp(
        address _weth,
        address _usdc,
        address _uni,
        address _factory
    ) public {
        usdc = _usdc; //new ERC20Mintable("USDC", "USDC", 18);
        weth = _weth; //new ERC20Mintable("Ether", "ETH", 18);
        uni = _uni; //new ERC20Mintable("Uniswap Coin", "UNI", 18);
        factory = _factory; //new UniswapV3Factory();
    }

    uint256 public data;

    function setData(uint256 _data) public {
        data = _data;
    }

    function setAddress(address _address) public {
        temp = _address;
    }

    function getData() public view returns (uint256) {
        return data;
    }

    function getAddress() public view returns (address) {
        return temp;
    }

    function processing() public {
        uint256 wethBalance = 100 ether;
        uint256 usdcBalance = 1000000 ether;
        uint256 uniBalance = 1000 ether;

        ERC20Mintable(weth).mint(address(this), wethBalance);
        ERC20Mintable(usdc).mint(address(this), usdcBalance);
        ERC20Mintable(uni).mint(address(this), uniBalance);

        manager = address(new UniswapV3Manager(factory));

        wethUSDC = address(
            deployPool(UniswapV3Factory(factory), weth, usdc, 3000, 5000)
        );
        wethUNI = address(
            deployPool(UniswapV3Factory(factory), weth, uni, 3000, 10)
        );

        ERC20Mintable(weth).approve(manager, wethBalance);
        ERC20Mintable(usdc).approve(manager, usdcBalance);
        ERC20Mintable(uni).approve(manager, uniBalance);

        UniswapV3Manager(manager).mint(
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

        UniswapV3Manager(manager).mint(
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

        quoter = address(new UniswapV3Quoter(factory));
    }

    function testQuoteUSDCforETH() public {
        (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            int24 tickAfter
        ) = UniswapV3Quoter(quoter).quoteSingle(
                UniswapV3Quoter.QuoteSingleParams({
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
        ) = UniswapV3Quoter(quoter).quoteSingle(
                UniswapV3Quoter.QuoteSingleParams({
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
        ) = UniswapV3Quoter(quoter).quote(path, 3 ether);

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
        (uint256 amountOut, , ) = UniswapV3Quoter(quoter).quote(path, amountIn);

        uint256 amountOutActual = UniswapV3Manager(manager).swap(
            IUniswapV3Manager.SwapParams({
                path: path,
                recipient: address(this),
                amountIn: amountIn,
                minAmountOut: amountOut
            })
        );

        assertEq(amountOutActual, amountOut, "invalid amount1Delta");
    }

    function testQuoteAndSwapUSDCforETH() public {
        uint256 amountIn = 0.01337 ether;
        (uint256 amountOut, , ) = UniswapV3Quoter(quoter).quoteSingle(
            UniswapV3Quoter.QuoteSingleParams({
                tokenIn: weth,
                tokenOut: usdc,
                fee: 3000,
                amountIn: amountIn,
                sqrtPriceLimitX96: sqrtP(4993)
            })
        );

        IUniswapV3Manager.SwapSingleParams memory swapParams = IUniswapV3Manager
            .SwapSingleParams({
                tokenIn: weth,
                tokenOut: usdc,
                fee: 3000,
                amountIn: amountIn,
                sqrtPriceLimitX96: sqrtP(4993)
            });
        uint256 amountOutActual = UniswapV3Manager(manager).swapSingle(
            swapParams
        );

        assertEq(amountOutActual, amountOut, "invalid amount1Delta");
    }

    function testQuoteAndSwapETHforUSDC() public {
        uint256 amountIn = 55 ether;
        (uint256 amountOut, , ) = UniswapV3Quoter(quoter).quoteSingle(
            UniswapV3Quoter.QuoteSingleParams({
                tokenIn: usdc,
                tokenOut: weth,
                fee: 3000,
                amountIn: amountIn,
                sqrtPriceLimitX96: sqrtP(5010)
            })
        );

        IUniswapV3Manager.SwapSingleParams memory swapParams = IUniswapV3Manager
            .SwapSingleParams({
                tokenIn: usdc,
                tokenOut: weth,
                fee: 3000,
                amountIn: amountIn,
                sqrtPriceLimitX96: sqrtP(5010)
            });
        uint256 amountOutActual = UniswapV3Manager(manager).swapSingle(
            swapParams
        );

        assertEq(amountOutActual, amountOut, "invalid amount0Delta");
    }
}
