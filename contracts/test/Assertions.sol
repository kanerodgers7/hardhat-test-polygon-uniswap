// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";

import "../UniswapV3Pool.sol";

import "./ERC20Mintable.sol";

abstract contract Assertions is Test {
    struct ExpectedPoolState {
        UniswapV3Pool pool;
        uint128 liquidity;
        uint160 sqrtPriceX96;
        int24 tick;
        uint256[2] fees;
    }

    function assertPoolState(ExpectedPoolState memory expected) internal {
        (uint160 sqrtPriceX96, int24 currentTick) = expected.pool.slot0();
        // assertEq(sqrtPriceX96, expected.sqrtPriceX96, "invalid current sqrtP");
        if (sqrtPriceX96 != expected.sqrtPriceX96) {
            setFailedStatus(true, "iinvalid current sqrtP");
            return;
        }
        // assertEq(currentTick, expected.tick, "invalid current tick");
        if (currentTick != expected.tick) {
            setFailedStatus(true, "iinvalid current tick");
            return;
        }
        // assertEq(
        //     expected.pool.liquidity(),
        //     expected.liquidity,
        //     "invalid current liquidity"
        // );
        if (expected.pool.liquidity() != expected.liquidity) {
            setFailedStatus(true, "iinvalid current liquidity");
            return;
        }

        // assertEq(
        //     expected.pool.feeGrowthGlobal0X128(),
        //     expected.fees[0],
        //     "incorrect feeGrowthGlobal0X128"
        // );
        if (expected.pool.feeGrowthGlobal0X128() != expected.fees[0]) {
            setFailedStatus(true, "incorrect feeGrowthGlobal0X128");
            return;
        }
        // assertEq(
        //     expected.pool.feeGrowthGlobal1X128(),
        //     expected.fees[1],
        //     "incorrect feeGrowthGlobal1X128"
        // );
        if (expected.pool.feeGrowthGlobal1X128() != expected.fees[1]) {
            setFailedStatus(true, "incorrect feeGrowthGlobal1X128");
            return;
        }
    }

    struct ExpectedBalances {
        UniswapV3Pool pool;
        ERC20Mintable[2] tokens;
        uint256 userBalance0;
        uint256 userBalance1;
        uint256 poolBalance0;
        uint256 poolBalance1;
    }

    function assertBalances(ExpectedBalances memory expected) internal {
        // assertEq(
        //     expected.tokens[0].balanceOf(address(this)),
        //     expected.userBalance0,
        //     "incorrect token0 balance of user"
        // );
        if (expected.tokens[0].balanceOf(address(this)) != expected.userBalance0) {
            setFailedStatus(true, "incorrect token0 balance of user");
            return;
        }
        // assertEq(
        //     expected.tokens[1].balanceOf(address(this)),
        //     expected.userBalance1,
        //     "incorrect token1 balance of user"
        // );
        if (expected.tokens[1].balanceOf(address(this)) != expected.userBalance1) {
            setFailedStatus(true, "incorrect token1 balance of user");
            return;
        }

        // assertEq(
        //     expected.tokens[0].balanceOf(address(expected.pool)),
        //     expected.poolBalance0,
        //     "incorrect token0 balance of pool"
        // );
        if (expected.tokens[0].balanceOf(address(expected.pool)) != expected.poolBalance0) {
            setFailedStatus(true, "incorrect token0 balance of pool");
            return;
        }
        // assertEq(
        //     expected.tokens[1].balanceOf(address(expected.pool)),
        //     expected.poolBalance1,
        //     "incorrect token1 balance of pool"
        // );
        if (expected.tokens[1].balanceOf(address(expected.pool)) != expected.poolBalance1) {
            setFailedStatus(true, "incorrect token0 balance of pool");
            return;
        }
    }

    struct ExpectedTick {
        UniswapV3Pool pool;
        int24 tick;
        bool initialized;
        uint128 liquidityGross;
        int128 liquidityNet;
    }

    struct ExpectedTickShort {
        int24 tick;
        bool initialized;
        uint128 liquidityGross;
        int128 liquidityNet;
    }

    function assertTick(ExpectedTick memory expected) internal {
        (
            bool initialized,
            uint128 liquidityGross,
            int128 liquidityNet,
            ,

        ) = expected.pool.ticks(expected.tick);
        // assertEq(
        //     initialized,
        //     expected.initialized,
        //     "incorrect tick initialized state"
        // );
        if (initialized != expected.initialized) {
            setFailedStatus(true, "incorrect tick initialized state");
            return;
        }
        // assertEq(
        //     liquidityGross,
        //     expected.liquidityGross,
        //     "incorrect tick gross liquidity"
        // );
        if (liquidityGross != expected.liquidityGross) {
            setFailedStatus(true, "incorrect tick gross state");
            return;
        }
        // assertEq(
        //     liquidityNet,
        //     expected.liquidityNet,
        //     "incorrect tick net liquidity"
        // );
        if (liquidityNet != expected.liquidityNet) {
            setFailedStatus(true, "incorrect tick net state");
            return;
        }

        // TODO: fix, must be the same as 'initialized'
        // assertEq(
        //     tickInBitMap(expected.pool, expected.tick),
        //     expected.initialized,
        //     "incorrect tick in bitmap state"
        // );
    }

    // struct ExpectedObservation {
    //     UniswapV3Pool pool;
    //     uint16 index;
    //     uint32 timestamp;
    //     int56 tickCumulative;
    //     bool initialized;
    // }

    // struct ExpectedObservationShort {
    //     uint16 index;
    //     uint32 timestamp;
    //     int56 tickCumulative;
    //     bool initialized;
    // }

    // function assertObservation(ExpectedObservation memory expected) internal {
    //     (uint32 timestamp, int56 tickCumulative, bool initialized) = expected
    //         .pool
    //         .observations(expected.index);

    //     assertEq(
    //         timestamp,
    //         expected.timestamp,
    //         "incorrect observation timestamp"
    //     );

    //     assertEq(
    //         tickCumulative,
    //         expected.tickCumulative,
    //         "incorrect observation cumulative tick"
    //     );

    //     assertEq(
    //         initialized,
    //         expected.initialized,
    //         "incorrect observation initialization state"
    //     );
    // }

    struct ExpectedMany {
        UniswapV3Pool pool;
        ERC20Mintable[2] tokens;
        // Pool
        uint128 liquidity;
        uint160 sqrtPriceX96;
        int24 tick;
        uint256[2] fees;
        // Balances
        uint256[2] userBalances;
        uint256[2] poolBalances;
        // Position
        ExpectedPositionShort position;
        // Ticks
        ExpectedTickShort[2] ticks;
        // Observation
        // ExpectedObservationShort observation;
    }

    function assertMany(ExpectedMany memory expected) internal {
        assertPoolState(
            ExpectedPoolState({
                pool: expected.pool,
                liquidity: expected.liquidity,
                sqrtPriceX96: expected.sqrtPriceX96,
                tick: expected.tick,
                fees: expected.fees
            })
        );
        assertBalances(
            ExpectedBalances({
                pool: expected.pool,
                tokens: expected.tokens,
                userBalance0: expected.userBalances[0],
                userBalance1: expected.userBalances[1],
                poolBalance0: expected.poolBalances[0],
                poolBalance1: expected.poolBalances[1]
            })
        );
        assertPosition(
            ExpectedPosition({
                pool: expected.pool,
                owner: expected.position.owner,
                ticks: expected.position.ticks,
                liquidity: expected.position.liquidity,
                feeGrowth: expected.position.feeGrowth,
                tokensOwed: expected.position.tokensOwed
            })
        );

        assertTick(
            ExpectedTick({
                pool: expected.pool,
                tick: expected.ticks[0].tick,
                initialized: expected.ticks[0].initialized,
                liquidityGross: expected.ticks[0].liquidityGross,
                liquidityNet: expected.ticks[0].liquidityNet
            })
        );

        assertTick(
            ExpectedTick({
                pool: expected.pool,
                tick: expected.ticks[1].tick,
                initialized: expected.ticks[1].initialized,
                liquidityGross: expected.ticks[1].liquidityGross,
                liquidityNet: expected.ticks[1].liquidityNet
            })
        );

        // assertObservation(
        //     ExpectedObservation({
        //         pool: expected.pool,
        //         index: expected.observation.index,
        //         timestamp: expected.observation.timestamp,
        //         tickCumulative: expected.observation.tickCumulative,
        //         initialized: expected.observation.initialized
        //     })
        // );
    }

    struct ExpectedPoolAndBalances {
        UniswapV3Pool pool;
        ERC20Mintable[2] tokens;
        // Pool
        uint128 liquidity;
        uint160 sqrtPriceX96;
        int24 tick;
        uint256[2] fees;
        // Balances
        uint256[2] userBalances;
        uint256[2] poolBalances;
    }

    function assertMany(ExpectedPoolAndBalances memory expected) internal {
        assertPoolState(
            ExpectedPoolState({
                pool: expected.pool,
                liquidity: expected.liquidity,
                sqrtPriceX96: expected.sqrtPriceX96,
                tick: expected.tick,
                fees: expected.fees
            })
        );
        assertBalances(
            ExpectedBalances({
                pool: expected.pool,
                tokens: expected.tokens,
                userBalance0: expected.userBalances[0],
                userBalance1: expected.userBalances[1],
                poolBalance0: expected.poolBalances[0],
                poolBalance1: expected.poolBalances[1]
            })
        );
    }

    struct ExpectedPositionAndTicks {
        UniswapV3Pool pool;
        // Position
        ExpectedPositionShort position;
        // Ticks
        ExpectedTickShort[2] ticks;
    }

    function assertMany(ExpectedPositionAndTicks memory expected) internal {
        assertPosition(
            ExpectedPosition({
                pool: expected.pool,
                owner: expected.position.owner,
                ticks: expected.position.ticks,
                liquidity: expected.position.liquidity,
                feeGrowth: expected.position.feeGrowth,
                tokensOwed: expected.position.tokensOwed
            })
        );

        assertTick(
            ExpectedTick({
                pool: expected.pool,
                tick: expected.ticks[0].tick,
                initialized: expected.ticks[0].initialized,
                liquidityGross: expected.ticks[0].liquidityGross,
                liquidityNet: expected.ticks[0].liquidityNet
            })
        );

        assertTick(
            ExpectedTick({
                pool: expected.pool,
                tick: expected.ticks[1].tick,
                initialized: expected.ticks[1].initialized,
                liquidityGross: expected.ticks[1].liquidityGross,
                liquidityNet: expected.ticks[1].liquidityNet
            })
        );
    }

    struct ExpectedPosition {
        UniswapV3Pool pool;
        address owner;
        int24[2] ticks;
        uint128 liquidity;
        uint256[2] feeGrowth;
        uint128[2] tokensOwed;
    }

    struct ExpectedPositionShort {
        address owner;
        int24[2] ticks;
        uint128 liquidity;
        uint256[2] feeGrowth;
        uint128[2] tokensOwed;
    }

    function assertPosition(ExpectedPosition memory params) public {
        bytes32 positionKey = keccak256(
            abi.encodePacked(params.owner, params.ticks[0], params.ticks[1])
        );
        (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = params.pool.positions(positionKey);

        // assertEq(liquidity, params.liquidity, "incorrect position liquidity");
        if (liquidity != params.liquidity) {
            setFailedStatus(true, "incorrect position liquidity");
            return;
        }
        // assertEq(
        //     feeGrowthInside0LastX128,
        //     params.feeGrowth[0],
        //     "incorrect position fee growth for token0"
        // );
        if (feeGrowthInside0LastX128 != params.feeGrowth[0]) {
            setFailedStatus(true, "incorrect position fee growth for token0");
            return;
        }
        // assertEq(
        //     feeGrowthInside1LastX128,
        //     params.feeGrowth[1],
        //     "incorrect position fee growth for token1"
        // );
        if (feeGrowthInside1LastX128 != params.feeGrowth[1]) {
            setFailedStatus(true, "incorrect position fee growth for token1");
            return;
        }
        // assertEq(
        //     tokensOwed0,
        //     params.tokensOwed[0],
        //     "incorrect position tokens owed for token0"
        // );
        if (tokensOwed0 != params.tokensOwed[0]) {
            setFailedStatus(true, "incorrect position tokens owed for token0");
            return;
        }
        // assertEq(
        //     tokensOwed1,
        //     params.tokensOwed[1],
        //     "incorrect position tokens owed for token1"
        // );
        if (tokensOwed1 != params.tokensOwed[1]) {
            setFailedStatus(true, "incorrect position tokens owed for token1");
            return;
        }
    }

    // function assertTokenURI(
    //     string memory actual,
    //     string memory expectedFixture,
    //     string memory errMessage
    // ) internal {
    //     string memory expected = vm.readFile(
    //         string.concat("./test/fixtures/", expectedFixture)
    //     );

    //     assertEq(actual, string(expected), errMessage);
    // }

    function tickInBitMap(
        UniswapV3Pool pool,
        int24 tick_
    ) internal view returns (bool initialized) {
        tick_ /= int24(pool.tickSpacing());

        int16 wordPos = int16(tick_ >> 8);
        uint8 bitPos = uint8(uint24(tick_ % 256));

        uint256 word = pool.tickBitmap(wordPos);

        initialized = (word & (1 << bitPos)) != 0;
    }
}
