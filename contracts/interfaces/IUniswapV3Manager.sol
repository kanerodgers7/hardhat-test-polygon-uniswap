// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

interface IUniswapV3Manager {
    struct PoolBasicInfo {
        address pool;
        address tokenA;
        address tokenB;
        uint24 fee;
    }

    struct GetPositionParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        address owner;
        int24 lowerTick;
        int24 upperTick;
    }

    struct GetAccumulatedFeeParams {
        address liquidityProvider;
        address tokenA;
        address tokenB;
        uint24 fee;
        address owner;
        int24 lowerTick;
        int24 upperTick;
    }

    struct GetOwnerAccumulatedFeeParams {
        address tokenA;
        address tokenB;
        uint24 fee;
    }

    struct CreatePoolParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        uint256 currentPrice;
        address tokenDonate;
    }

    struct GetLiquidityparams {
        address tokenA;
        address tokenB;
        uint24 fee;
        address owner;
        int24 lowerTick;
        int24 upperTick;
    }

    struct MintParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        int24 lowerTick;
        int24 upperTick;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    struct SwapSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amountIn;
    }

    struct SwapParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 minAmountOut;
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    struct BurnParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
    }

    struct CollectParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        address recipient;
        int24 lowerTick;
        int24 upperTick;
        uint128 amount0Desired;
        uint128 amount1Desired;
    }

    struct CollectOwnerParams {
        address tokenA;
        address tokenB;
        uint24 fee;
        address recipient;
    }

    struct GetTotalVolumeOfPool {
        address tokenA;
        address tokenB;
        uint24 fee;
    }
}
