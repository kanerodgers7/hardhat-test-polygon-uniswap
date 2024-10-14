// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "./TestUtils.sol";

import "../interfaces/IUniswapV3Pool.sol";
import "../StratoSwapFactory.sol";
import "../StratoSwapPool.sol";

contract UniswapV3FactoryTest is Test, TestUtils {
    function testCreatePool(
        address factory,
        address weth,
        address usdc
    ) public {
        address poolAddress = StratoSwapFactory(factory).createPool(
            weth,
            usdc,
            500
        );

        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);

        if (StratoSwapFactory(factory).pools(usdc, weth, 500) != poolAddress) {
            setFailedStatus(true, "invalid pool address in the registry");
            return;
        }

        if (StratoSwapFactory(factory).pools(weth, usdc, 500) != poolAddress) {
            setFailedStatus(
                true,
                "invalid pool address in the registry (reverse order)"
            );
            return;
        }

        if (pool.factory() != address(factory)) {
            setFailedStatus(true, "invalid factory address");
            return;
        }
        if (pool.token0() != weth) {
            setFailedStatus(true, "invalid weth address");
            return;
        }
        if (pool.token1() != usdc) {
            setFailedStatus(true, "invalid usdc address");
            return;
        }
        if (pool.tickSpacing() != 10) {
            setFailedStatus(true, "invalid tick spacing");
            return;
        }
        if (pool.fee() != 500) {
            setFailedStatus(true, "invalid fee");
            return;
        }

        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        if (sqrtPriceX96 != 0) {
            setFailedStatus(true, "invalid sqrtPriceX96");
            return;
        }
        if (tick != 0) {
            setFailedStatus(true, "invalid tick");
            return;
        }
    }

    function testCreatePoolUnsupportedFee(
        address factory,
        address weth,
        address usdc
    ) public {
        try StratoSwapFactory(factory).createPool(weth, usdc, 300) {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory) {
            // This is executed in case of a revert with a reason string
            setFailedStatus(true, "Unexpected error with reason");
        } catch (bytes memory) {
            // This is executed in case of a revert without a reason string
        }
    }

    function testCreatePoolIdenticalTokens(
        address factory,
        address weth
    ) public {
        try StratoSwapFactory(factory).createPool(weth, weth, 500) {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory) {
            // This is executed in case of a revert with a reason string
            setFailedStatus(true, "Unexpected error with reason");
        } catch (bytes memory) {
            // This is executed in case of a revert without a reason string
        }
    }

    function testCreateZeroTokenAddress(address factory, address weth) public {
        try StratoSwapFactory(factory).createPool(weth, address(0), 500) {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory) {
            // This is executed in case of a revert with a reason string
            setFailedStatus(true, "Unexpected error with reason");
        } catch (bytes memory) {
            // This is executed in case of a revert without a reason string
        }
    }

    function testCreateAlreadyExists(
        address factory,
        address weth,
        address usdc
    ) public {
        StratoSwapFactory(factory).createPool(weth, usdc, 500);

        try StratoSwapFactory(factory).createPool(weth, usdc, 500) {
            // Handle successful pool creation
            setFailedStatus(true, "Unexpected error");
        } catch Error(string memory) {
            // This is executed in case of a revert with a reason string
            setFailedStatus(true, "Unexpected error with reason");
        } catch (bytes memory) {
            // This is executed in case of a revert without a reason string
        }
    }
}
