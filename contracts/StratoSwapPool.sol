// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "prb-math/contracts/PRBMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3MintCallback.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IUniswapV3PoolDeployer.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";

import "./lib/FixedPoint128.sol";
import "./lib/LiquidityMath.sol";
import "./lib/Math.sol";
import "./lib/Position.sol";
import "./lib/SwapMath.sol";
import "./lib/Tick.sol";
import "./lib/TickBitmap.sol";
import "./lib/TickMath.sol";

contract StratoSwapPool is IUniswapV3Pool {
    using Position for Position.Info;
    using Position for mapping(bytes32 => Position.Info);
    using Tick for mapping(int24 => Tick.Info);
    using TickBitmap for mapping(int16 => uint256);

    error AlreadyInitialized();
    error InsufficientInputAmount();
    error InvalidPriceLimit();
    error InvalidTickRange();
    error NotEnoughLiquidity();
    error ZeroLiquidity();
    error InsufficientWithParam(
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256
    );

    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint256 amount0,
        uint256 amount1
    );

    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// Pool parameters
    address public manager;
    address public factory;
    address public immutable token0;
    address public immutable token1;
    uint24 public immutable tickSpacing;
    uint24 public immutable fee;

    uint256 public feeGrowthGlobal0X128;
    uint256 public feeGrowthGlobal1X128;

    uint256 public profitOwnerToken0;
    uint256 public profitOwnerToken1;

    address public DONATE_TOKEN_ADDRESS; // Should replace the USDC token address here

    /// First slot will contain essential data
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
    }

    struct StandardSlot0 {
        /// standard sqrt(P)
        uint160 sqrtPriceX96;
        /// standard tick
        int24 standardTick;
        /// the low tick (-20% of the standard price)
        int24 standatdLowTick;
        /// the up tick (+20% of the standard price)
        int24 standardUpTick;
    }

    struct SwapState {
        uint256 amountSpecifiedRemaining;
        uint256 amountCalculated;
        uint160 sqrtPriceX96;
        int24 tick;
        uint256 feeGrowthGlobalX128;
        uint128 liquidity;
    }

    struct StepState {
        uint160 sqrtPriceStartX96;
        int24 nextTick;
        bool initialized;
        uint160 sqrtPriceNextX96;
        uint256 amountIn;
        uint256 amountOut;
        uint256 feeAmount;
    }

    Slot0 public slot0;
    StandardSlot0 public standardSlot0;

    /// Amount of liquidity, L.
    uint128 public liquidity;

    mapping(int24 => Tick.Info) public ticks;
    mapping(int16 => uint256) public tickBitmap;
    mapping(bytes32 => Position.Info) public positions;

    mapping(address => IUniswapV3Pool.LiquidityState[]) public liquiditiesList;
    mapping(address => uint256) public donatedAmountList;
    address[] public liquidityProviders;

    constructor() {
        (factory, token0, token1, tickSpacing, fee) = IUniswapV3PoolDeployer(
            msg.sender
        ).parameters();
        profitOwnerToken0 = 0;
        profitOwnerToken1 = 0;
    }

    function getDonatedTokenAddress() external view returns (address) {
        return DONATE_TOKEN_ADDRESS;
    }

    function updateStandardTick() public returns (int24 tickUp, int24 tickLow) {
        int24 tick = slot0.tick;
        uint160 sqrtPriceX96 = slot0.sqrtPriceX96;
        tickLow = int24((int256(tick) * 894427190) / 1e9);
        tickUp = int24((int256(tick) * 1118033988) / 1e9);
        tickLow = Math.nearestUsableTick(tickLow, tickSpacing);
        tickUp = Math.nearestUsableTick(tickUp, tickSpacing);
        if (tickLow > tickUp) (tickLow, tickUp) = (tickUp, tickLow);
        if (tickLow < -887272) tickLow = -887272;
        if (tickUp > 887272) tickUp = 887272;
        standardSlot0 = StandardSlot0({
            sqrtPriceX96: sqrtPriceX96,
            standardTick: tick,
            standatdLowTick: tickLow,
            standardUpTick: tickUp
        });
    }

    function initialize(
        uint160 sqrtPriceX96,
        address tokenDonate
    ) external returns (int24, int24) {
        if (slot0.sqrtPriceX96 != 0) revert AlreadyInitialized();

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick});

        manager = msg.sender;

        DONATE_TOKEN_ADDRESS = tokenDonate;

        return updateStandardTick();
    }

    struct ModifyPositionParams {
        address owner;
        int24 lowerTick;
        int24 upperTick;
        int128 liquidityDelta;
    }

    function getLiquidityByAddress(
        address owner
    ) external view returns (IUniswapV3Pool.LiquidityState[] memory) {
        return liquiditiesList[owner];
    }

    function getDonatedAmount(address owner) external view returns (uint256) {
        return donatedAmountList[owner];
    }

    function donate(uint256 amount) external {
        uint256 i;
        uint256 j;
        for (i = 0; i < liquidityProviders.length; i++) {
            uint128 liquidityTotal = 0;
            IUniswapV3Pool.LiquidityState[]
                memory liquidities = liquiditiesList[liquidityProviders[i]];
            for (j = 0; j < liquidities.length; j++)
                liquidityTotal += liquidities[j].liquidity;
            donatedAmountList[liquidityProviders[i]] =
                (amount * liquidityTotal) /
                liquidity;
        }
    }

    function withdrawDonatedAmount(address owner) external {
        IERC20(DONATE_TOKEN_ADDRESS).transfer(owner, donatedAmountList[owner]);
        donatedAmountList[owner] = 0;
    }

    function _modifyPosition(
        ModifyPositionParams memory params
    )
        internal
        returns (Position.Info storage position, int256 amount0, int256 amount1)
    {
        // gas optimizations
        Slot0 memory slot0_ = slot0;
        uint256 feeGrowthGlobal0X128_ = feeGrowthGlobal0X128;
        uint256 feeGrowthGlobal1X128_ = feeGrowthGlobal1X128;

        position = positions.get(
            params.owner,
            params.lowerTick,
            params.upperTick
        );

        bool flippedLower = ticks.update(
            params.lowerTick,
            slot0_.tick,
            int128(params.liquidityDelta),
            feeGrowthGlobal0X128_,
            feeGrowthGlobal1X128_,
            false
        );
        bool flippedUpper = ticks.update(
            params.upperTick,
            slot0_.tick,
            int128(params.liquidityDelta),
            feeGrowthGlobal0X128_,
            feeGrowthGlobal1X128_,
            true
        );

        if (flippedLower) {
            tickBitmap.flipTick(params.lowerTick, int24(tickSpacing));
        }

        if (flippedUpper) {
            tickBitmap.flipTick(params.upperTick, int24(tickSpacing));
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = ticks
            .getFeeGrowthInside(
                params.lowerTick,
                params.upperTick,
                slot0_.tick,
                feeGrowthGlobal0X128_,
                feeGrowthGlobal1X128_
            );

        position.update(
            params.liquidityDelta,
            feeGrowthInside0X128,
            feeGrowthInside1X128
        );

        if (slot0_.tick < params.lowerTick) {
            amount0 = Math.calcAmount0Delta(
                TickMath.getSqrtRatioAtTick(params.lowerTick),
                TickMath.getSqrtRatioAtTick(params.upperTick),
                params.liquidityDelta
            );
        } else if (slot0_.tick < params.upperTick) {
            amount0 = Math.calcAmount0Delta(
                slot0_.sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(params.upperTick),
                params.liquidityDelta
            );

            amount1 = Math.calcAmount1Delta(
                TickMath.getSqrtRatioAtTick(params.lowerTick),
                slot0_.sqrtPriceX96,
                params.liquidityDelta
            );

            liquidity = LiquidityMath.addLiquidity(
                liquidity,
                params.liquidityDelta
            );

            uint256 i;
            if (liquiditiesList[params.owner].length == 0)
                liquidityProviders.push(params.owner);
            IUniswapV3Pool.LiquidityState[]
                storage liquidities = liquiditiesList[params.owner];
            for (i = 0; i < liquidities.length; i++)
                if (
                    liquidities[i].lowerTick == params.lowerTick &&
                    liquidities[i].upperTick == params.upperTick
                ) {
                    liquidities[i].liquidity = LiquidityMath.addLiquidity(
                        liquidities[i].liquidity,
                        params.liquidityDelta
                    );
                    break;
                }
            if (i == liquidities.length)
                liquidities.push(
                    IUniswapV3Pool.LiquidityState({
                        lowerTick: params.lowerTick,
                        upperTick: params.upperTick,
                        liquidity: uint128(params.liquidityDelta)
                    })
                );
        } else {
            amount1 = Math.calcAmount1Delta(
                TickMath.getSqrtRatioAtTick(params.lowerTick),
                TickMath.getSqrtRatioAtTick(params.upperTick),
                params.liquidityDelta
            );
        }
    }

    error MintableError(uint256, uint256, uint256);

    function mint(
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1) {
        if (
            lowerTick >= upperTick ||
            lowerTick < TickMath.MIN_TICK ||
            upperTick > TickMath.MAX_TICK
        ) revert InvalidTickRange();
        if (
            lowerTick % int24(tickSpacing) != 0 ||
            upperTick % int24(tickSpacing) != 0
        ) revert("Invalid uppertick and lowertick");

        if (amount == 0) revert ZeroLiquidity();

        (, int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: owner,
                lowerTick: lowerTick,
                upperTick: upperTick,
                liquidityDelta: int128(amount)
            })
        );

        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);

        uint256 balance0Before;
        uint256 balance1Before;

        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();

        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(
            amount0,
            amount1,
            data
        );

        if (amount0 > 0 && balance0Before + amount0 > balance0())
            revert InsufficientInputAmount();

        if (amount1 > 0 && balance1Before + amount1 > balance1()) {
            revert InsufficientInputAmount();
        }

        emit Mint(
            msg.sender,
            owner,
            lowerTick,
            upperTick,
            amount,
            amount0,
            amount1
        );
    }

    function burn(
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 amount
    ) public returns (uint256 amount0, uint256 amount1) {
        (
            Position.Info storage position,
            int256 amount0Int,
            int256 amount1Int
        ) = _modifyPosition(
                ModifyPositionParams({
                    owner: owner,
                    lowerTick: lowerTick,
                    upperTick: upperTick,
                    liquidityDelta: -(int128(amount))
                })
            );

        amount0 = uint256(-amount0Int);
        amount1 = uint256(-amount1Int);

        if (amount0 > 0 || amount1 > 0) {
            (position.tokensOwed0, position.tokensOwed1) = (
                position.tokensOwed0 + uint128(amount0),
                position.tokensOwed1 + uint128(amount1)
            );
        }

        emit Burn(owner, lowerTick, upperTick, amount, amount0, amount1);
    }

    function collect(
        address owner,
        address recipient,
        int24 lowerTick,
        int24 upperTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) public returns (uint128 amount0, uint128 amount1) {
        Position.Info storage position = positions.get(
            owner,
            lowerTick,
            upperTick
        );
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = ticks
            .getFeeGrowthInside(
                lowerTick,
                upperTick,
                slot0.tick,
                feeGrowthGlobal0X128,
                feeGrowthGlobal1X128
            );
        position.update(0, feeGrowthInside0X128, feeGrowthInside1X128);
        uint128 bonusFee = 0;
        if (
            lowerTick != standardSlot0.standatdLowTick ||
            upperTick != standardSlot0.standardUpTick
        ) bonusFee = 10000;

        amount0 = amount0Requested > position.tokensOwed0
            ? position.tokensOwed0
            : amount0Requested;
        amount1 = amount1Requested > position.tokensOwed1
            ? position.tokensOwed1
            : amount1Requested;

        if (amount0 > 0) {
            position.tokensOwed0 -= amount0;
            if (bonusFee > 0) {
                profitOwnerToken0 = profitOwnerToken0 + (amount0 - amount0 * 99 / 100);
                amount0 = (amount0 * 99) / 100;
            }
            IERC20(token0).transfer(recipient, amount0);
        }

        if (amount1 > 0) {
            position.tokensOwed1 -= amount1;
            if (bonusFee > 0) {
                profitOwnerToken1 = profitOwnerToken1 + (amount1 - amount1 * 99 / 100);
                amount1 = (amount1 * 99) / 100;
            }
            IERC20(token1).transfer(recipient, amount1);
        }

        emit Collect(owner, recipient, lowerTick, upperTick, amount0, amount1);
    }

    function swap(
        address recipient,
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) public returns (int256 amount0, int256 amount1) {
        // Caching for gas saving
        Slot0 memory slot0_ = slot0;
        uint128 liquidity_ = liquidity;

        if (
            zeroForOne
                ? sqrtPriceLimitX96 > slot0_.sqrtPriceX96 ||
                    sqrtPriceLimitX96 < TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 < slot0_.sqrtPriceX96 ||
                    sqrtPriceLimitX96 > TickMath.MAX_SQRT_RATIO
        ) revert InvalidPriceLimit();

        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: slot0_.sqrtPriceX96,
            tick: slot0_.tick,
            feeGrowthGlobalX128: zeroForOne
                ? feeGrowthGlobal0X128
                : feeGrowthGlobal1X128,
            liquidity: liquidity_
        });

        while (
            state.amountSpecifiedRemaining > 0 &&
            state.sqrtPriceX96 != sqrtPriceLimitX96
        ) {
            StepState memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.nextTick, step.initialized) = tickBitmap
                .nextInitializedTickWithinOneWord(
                    state.tick,
                    int24(tickSpacing),
                    zeroForOne
                );

            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.nextTick);

            (
                state.sqrtPriceX96,
                step.amountIn,
                step.amountOut,
                step.feeAmount
            ) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (
                    zeroForOne
                        ? step.sqrtPriceNextX96 < sqrtPriceLimitX96
                        : step.sqrtPriceNextX96 > sqrtPriceLimitX96
                )
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                fee
            );

            state.amountSpecifiedRemaining -= step.amountIn + step.feeAmount;
            state.amountCalculated += step.amountOut;

            if (state.liquidity > 0) {
                state.feeGrowthGlobalX128 += PRBMath.mulDiv(
                    step.feeAmount,
                    FixedPoint128.Q128,
                    state.liquidity
                );
            }

            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                if (step.initialized) {
                    int128 liquidityDelta = ticks.cross(
                        step.nextTick,
                        (
                            zeroForOne
                                ? state.feeGrowthGlobalX128
                                : feeGrowthGlobal0X128
                        ),
                        (
                            zeroForOne
                                ? feeGrowthGlobal1X128
                                : state.feeGrowthGlobalX128
                        )
                    );

                    if (zeroForOne) liquidityDelta = -liquidityDelta;

                    state.liquidity = LiquidityMath.addLiquidity(
                        state.liquidity,
                        liquidityDelta
                    );

                    if (state.liquidity == 0) revert NotEnoughLiquidity();
                }

                state.tick = zeroForOne ? step.nextTick - 1 : step.nextTick;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        if (state.tick != slot0_.tick) {
            (slot0.sqrtPriceX96, slot0.tick) = (state.sqrtPriceX96, state.tick);
        } else {
            slot0.sqrtPriceX96 = state.sqrtPriceX96;
        }

        if (liquidity_ != state.liquidity) liquidity = state.liquidity;

        if (zeroForOne) {
            feeGrowthGlobal0X128 = state.feeGrowthGlobalX128;
        } else {
            feeGrowthGlobal1X128 = state.feeGrowthGlobalX128;
        }

        (amount0, amount1) = zeroForOne
            ? (
                int256(amountSpecified - state.amountSpecifiedRemaining),
                -int256(state.amountCalculated)
            )
            : (
                -int256(state.amountCalculated),
                int256(amountSpecified - state.amountSpecifiedRemaining)
            );

        if (zeroForOne) {
            IERC20(token1).transfer(recipient, uint256(-amount1));

            uint256 balance0Before = balance0();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
                amount0,
                amount1,
                data
            );
            if (balance0Before + uint256(amount0) > balance0())
                revert InsufficientInputAmount();
        } else {
            IERC20(token0).transfer(recipient, uint256(-amount0));

            uint256 balance1Before = balance1();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
                amount0,
                amount1,
                data
            );
            if (balance1Before + uint256(amount1) > balance1())
                revert InsufficientInputAmount();
        }

        emit Swap(
            msg.sender,
            recipient,
            amount0,
            amount1,
            slot0.sqrtPriceX96,
            state.liquidity,
            slot0.tick
        );
    }

    function collectOwnerFee(
        address recipient
    ) external returns (uint256 profitOwnerToken0_, uint256 profitOwnerToken1_) {
        require(msg.sender == manager, "Caller hasn't ownership to collect");
        require(
            profitOwnerToken0 != 0 || profitOwnerToken1 != 0,
            "Profit is zero"
        );
        IERC20(token0).transfer(recipient, profitOwnerToken0);
        IERC20(token1).transfer(recipient, profitOwnerToken1);
        profitOwnerToken0_ = profitOwnerToken0;
        profitOwnerToken1_ = profitOwnerToken1;
        profitOwnerToken0 = 0;
        profitOwnerToken1 = 0;
    }

    error MintabError(uint256, uint256);
    function getAccumulatedFee(
        address owner,
        int24 lowerTick,
        int24 upperTick
    ) external view returns (uint256 amount0, uint256 amount1) {
        Position.Info storage position = positions.get(
            owner,
            lowerTick,
            upperTick
        );
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = ticks
            .getFeeGrowthInside(
                lowerTick,
                upperTick,
                slot0.tick,
                feeGrowthGlobal0X128,
                feeGrowthGlobal1X128
            );

        (amount0, amount1) = position.calcAccumalatedAmount(feeGrowthInside0X128, feeGrowthInside1X128);
    }

    function getOwnerAccumulatedFee() external view returns (uint256, uint256) {
        return (profitOwnerToken0, profitOwnerToken1);
    }

    ////////////////////////////////////////////////////////////////////////////
    //
    // INTERNAL
    //
    ////////////////////////////////////////////////////////////////////////////
    function balance0() internal view returns (uint256 balance) {
        balance = IERC20(token0).balanceOf(address(this)) - profitOwnerToken0;
    }

    function balance1() internal view returns (uint256 balance) {
        balance = IERC20(token1).balanceOf(address(this)) - profitOwnerToken1;
    }

    function _blockTimestamp() internal view returns (uint32 timestamp) {
        timestamp = uint32(block.timestamp);
    }
}
