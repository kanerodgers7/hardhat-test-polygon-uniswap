// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

import "./FixedPoint96.sol";
import "./TickMath.sol";
import "prb-math/contracts/PRBMath.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";

library Math {
    /// @notice Calculates amount0 delta between two prices
    function calcAmount0Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        require(sqrtPriceAX96 > 0);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtPriceBX96 - sqrtPriceAX96;

        if (roundUp) {
            amount0 = divRoundingUp(
                mulDivRoundingUp(numerator1, numerator2, sqrtPriceBX96),
                sqrtPriceAX96
            );
        } else {
            amount0 =
                PRBMath.mulDiv(numerator1, numerator2, sqrtPriceBX96) /
                sqrtPriceAX96;
        }
    }

    /// @notice Calculates amount1 delta between two prices
    function calcAmount1Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtPriceAX96 > sqrtPriceBX96)
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);

        if (roundUp) {
            amount1 = mulDivRoundingUp(
                liquidity,
                (sqrtPriceBX96 - sqrtPriceAX96),
                FixedPoint96.Q96
            );
        } else {
            amount1 = PRBMath.mulDiv(
                liquidity,
                (sqrtPriceBX96 - sqrtPriceAX96),
                FixedPoint96.Q96
            );
        }
    }

    /// @notice Calculates amount0 delta between two prices
    function calcAmount0Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        amount0 = liquidity < 0
            ? -int256(
                calcAmount0Delta(
                    sqrtPriceAX96,
                    sqrtPriceBX96,
                    uint128(-liquidity),
                    false
                )
            )
            : int256(
                calcAmount0Delta(
                    sqrtPriceAX96,
                    sqrtPriceBX96,
                    uint128(liquidity),
                    true
                )
            );
    }

    /// @notice Calculates amount1 delta between two prices
    function calcAmount1Delta(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        amount1 = liquidity < 0
            ? -int256(
                calcAmount1Delta(
                    sqrtPriceAX96,
                    sqrtPriceBX96,
                    uint128(-liquidity),
                    false
                )
            )
            : int256(
                calcAmount1Delta(
                    sqrtPriceAX96,
                    sqrtPriceBX96,
                    uint128(liquidity),
                    true
                )
            );
    }

    function getNextSqrtPriceFromInput(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtPriceNextX96) {
        sqrtPriceNextX96 = zeroForOne
            ? getNextSqrtPriceFromAmount0RoundingUp(
                sqrtPriceX96,
                liquidity,
                amountIn
            )
            : getNextSqrtPriceFromAmount1RoundingDown(
                sqrtPriceX96,
                liquidity,
                amountIn
            );
    }

    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn
    ) internal pure returns (uint160) {
        uint256 numerator = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 product = amountIn * sqrtPriceX96;

        // If product doesn't overflow, use the precise formula.
        if (product / amountIn == sqrtPriceX96) {
            uint256 denominator = numerator + product;
            if (denominator >= numerator) {
                return
                    uint160(
                        mulDivRoundingUp(numerator, sqrtPriceX96, denominator)
                    );
            }
        }

        // If product overflows, use a less precise formula.
        return
            uint160(
                divRoundingUp(numerator, (numerator / sqrtPriceX96) + amountIn)
            );
    }

    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPriceX96,
        uint128 liquidity,
        uint256 amountIn
    ) internal pure returns (uint160) {
        return
            uint160(
                uint256(sqrtPriceX96) +
                    PRBMath.mulDiv(amountIn, FixedPoint96.Q96, liquidity)
            );
    }

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    function divRoundingUp(
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        assembly {
            result := add(
                div(numerator, denominator),
                gt(mod(numerator, denominator), 0)
            )
        }
    }

    function sqrtP(uint256 price) internal pure returns (uint160) {
        return
            uint160(
                int160(
                    ABDKMath64x64.sqrt(int128(int256(price << 64))) <<
                        (FixedPoint96.RESOLUTION - 64)
                )
            );
    }
    
    function sqrtPFromDecimal(uint256 price) internal pure returns (uint160) {
        return
            uint160(
                int160(
                    (ABDKMath64x64.sqrt(int128(int256(price))) / 1000000000) <<
                        (FixedPoint96.RESOLUTION - 32)
                )
            );
    }

    function divRound(
        int128 x,
        int128 y
    ) internal pure returns (int128 result) {
        int128 quot = ABDKMath64x64.div(x, y);
        result = quot >> 64;

        // Check if remainder is greater than 0.5
        if (quot % 2 ** 64 >= 0x8000000000000000) {
            result += 1;
        }
    }

    function nearestUsableTick(
        int24 tick_,
        uint24 tickSpacing
    ) internal pure returns (int24 result) {
        result =
            int24(divRound(int128(tick_), int128(int24(tickSpacing)))) *
            int24(tickSpacing);

        if (result < TickMath.MIN_TICK) {
            result += int24(tickSpacing);
        } else if (result > TickMath.MAX_TICK) {
            result -= int24(tickSpacing);
        }
    }
}
