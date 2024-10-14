// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IPSTToken.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IUniswapV3Manager.sol";
import "./lib/LiquidityMath.sol";
import "./lib/Path.sol";
import "./lib/Math.sol";
import "./lib/PoolAddress.sol";
import "./lib/TickMath.sol";
import "./StratoSwapFactory.sol";

contract StratoSwapManagerHelper is IUniswapV3Manager {

    address public immutable factory;

    constructor(address factory_) {
        factory = factory_;
    }

    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (IUniswapV3Pool pool) {
        (token0, token1) = token0 < token1
            ? (token0, token1)
            : (token1, token0);
        pool = IUniswapV3Pool(
            PoolAddress.computeAddress(factory, token0, token1, fee)
        );
    }

    function getAccumulatedFeeAmount(
        address liquidityProvider,
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 lowerTick,
        int24 upperTick
    ) external view returns (uint256 tokensOwed0, uint256 tokensOwed1) {
        IUniswapV3Pool pool = getPool(tokenA, tokenB, fee);
        
        (tokensOwed0, tokensOwed1) = pool.getAccumulatedFee(liquidityProvider, lowerTick, upperTick);
    }

    function getLiquidityByAddress(
        address liquidityProvider,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (IUniswapV3Pool.LiquidityState[] memory) {
        IUniswapV3Pool pool = getPool(tokenA, tokenB, fee);

        return pool.getLiquidityByAddress(liquidityProvider);
    }

    function getDonatedAmount(
        address liquidityProvider,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (uint256) {
        IUniswapV3Pool pool = getPool(tokenA, tokenB, fee);

        return pool.getDonatedAmount(liquidityProvider);
    }

    error MintableError(uint256);
    function donate(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint256 amount
    ) external {
        IUniswapV3Pool pool = getPool(tokenA, tokenB, fee);
        address DONATE_TOKEN_ADDRSS = pool.getDonatedTokenAddress();
        IERC20(DONATE_TOKEN_ADDRSS).transferFrom(
            msg.sender,
            address(pool),
            amount
        );
        pool.donate(amount);
    }

    function withdrawDonatedAmount(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external {
        IUniswapV3Pool pool = getPool(tokenA, tokenB, fee);
        pool.withdrawDonatedAmount(msg.sender);
    }

    function getStandardSlot0(
        address token0,
        address token1,
        uint24 fee
    )
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 standardTick,
            int24 standatdLowTick,
            int24 standardUpTick
        )
    {
        IUniswapV3Pool pool = getPool(token0, token1, fee);
        (sqrtPriceX96, standardTick, standatdLowTick, standardUpTick) = pool
            .standardSlot0();
    }

    function getOwnerAccumulatedFeeAmount(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (uint256 token0, uint256 token1) {
        IUniswapV3Pool pool = getPool(tokenA, tokenB, fee);
        (token0, token1) = pool.getOwnerAccumulatedFee();
    }

    function getLiquidity(
        address tokenA,
        address tokenB,
        uint24 fee,
        address owner_,
        int24 lowerTick,
        int24 upperTick
    ) external view returns (uint128) {
        IUniswapV3Pool pool = getPool(tokenA, tokenB, fee);

        (uint128 liquidity, , , , ) = pool.positions(
            keccak256(abi.encodePacked(owner_, lowerTick, upperTick))
        );
        return liquidity;
    }

    function getTotalVolumeOfPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (uint256 amount0, uint256 amount1) {
        StratoSwapFactory factoryContract = StratoSwapFactory(factory);
        address pool = factoryContract.getPoolAddress(tokenA, tokenB, fee);

        if (pool == address(0)) revert("Pool not existed!");

        amount0 = IERC20(tokenA).balanceOf(pool);
        amount1 = IERC20(tokenB).balanceOf(pool);
    }
}
