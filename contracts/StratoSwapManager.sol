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

contract StratoSwapManager is IUniswapV3Manager {
    using Path for bytes;

    error SlippageCheckFailed(uint256 amount0, uint256 amount1);
    error TooLittleReceived(uint256 amountOut);

    event Minted(uint256 amount0, uint256 amount1);
    event SwapOut(uint256 amountOut);
    event Burned(uint256 amount0, uint256 amount1);
    event Collected(uint256 amount0, uint256 amount1);

    address public owner;
    address public immutable factory;
    mapping(address => bool) public pstTokens;

    PoolBasicInfo[] public poolInfos;

    constructor(address factory_) {
        factory = factory_;
        owner = msg.sender;
    }

    function getPoolAddresses() public view returns (PoolBasicInfo[] memory) {
        return poolInfos;
    }

    function checkPSToken(address token1) public returns (bool) {
        try IPSTToken(token1).isPst() {
            pstTokens[token1] = true;
        } catch Error(string memory) {
            pstTokens[token1] = false;
        } catch (bytes memory) {
            pstTokens[token1] = false;
        }
        return pstTokens[token1];
    }

    function createPool(
        CreatePoolParams calldata params
    ) public returns (address pool) {
        require(owner == msg.sender, "Message sender should be owner");
        StratoSwapFactory factoryContract = StratoSwapFactory(factory);
        pool = factoryContract.getPoolAddress(
            params.tokenA,
            params.tokenB,
            params.fee
        );
        if (pool != address(0)) revert("Pool already existed!");

        checkPSToken(params.tokenA);
        checkPSToken(params.tokenB);

        pool = factoryContract.createPool(
            params.tokenA,
            params.tokenB,
            params.fee
        );
        IUniswapV3Pool(pool).initialize(
            Math.sqrtPFromDecimal(params.currentPrice),
            params.tokenDonate
        );
        poolInfos.push(
            PoolBasicInfo({
                pool: pool,
                tokenA: params.tokenA,
                tokenB: params.tokenB,
                fee: params.fee
            })
        );
    }

    function mint(
        MintParams calldata params
    ) public returns (uint256 amount0, uint256 amount1) {
        StratoSwapFactory factoryContract = StratoSwapFactory(factory);
        if (
            factoryContract.getPoolAddress(
                params.tokenA,
                params.tokenB,
                params.fee
            ) == address(0)
        ) revert("Pool not existed!");
        if (params.tokenA > params.tokenB)
            revert("tokenA address should be higher than tokenB address");

        IUniswapV3Pool pool = getPool(params.tokenA, params.tokenB, params.fee);

        (uint160 sqrtPriceX96, ) = pool.slot0();
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(
            params.lowerTick
        );
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(
            params.upperTick
        );

        uint128 liquidity = LiquidityMath.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtPriceLowerX96,
            sqrtPriceUpperX96,
            params.amount0Desired,
            params.amount1Desired
        );

        (amount0, amount1) = pool.mint(
            msg.sender,
            params.lowerTick,
            params.upperTick,
            liquidity,
            abi.encode(
                IUniswapV3Pool.CallbackData({
                    token0: pool.token0(),
                    token1: pool.token1(),
                    payer: msg.sender
                })
            )
        );

        emit Minted(amount0, amount1);
        if (amount0 < params.amount0Min || amount1 < params.amount1Min)
            revert SlippageCheckFailed(amount0, amount1);
        
    }

    function swapSingle(
        SwapSingleParams calldata params
    ) public returns (uint256 amountOut) {
        amountOut = _swap(
            params.amountIn,
            msg.sender,
            SwapCallbackData({
                path: abi.encodePacked(
                    params.tokenIn,
                    params.fee,
                    params.tokenOut
                ),
                payer: msg.sender
            })
        );
        emit SwapOut(amountOut);
    }

    function swap(SwapParams memory params) public returns (uint256 amountOut) {
        address payer = msg.sender;
        bool hasMultiplePools;

        while (true) {
            hasMultiplePools = params.path.hasMultiplePools();

            params.amountIn = _swap(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient,
                SwapCallbackData({
                    path: params.path.getFirstPool(),
                    payer: payer
                })
            );

            if (hasMultiplePools) {
                payer = address(this);
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        emit SwapOut(amountOut);
        if (amountOut < params.minAmountOut)
            revert TooLittleReceived(amountOut);

    }

    function _swap(
        uint256 amountIn,
        address recipient,
        SwapCallbackData memory data
    ) internal returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, uint24 fee) = data
            .path
            .decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = getPool(tokenIn, tokenOut, fee).swap(
            recipient,
            zeroForOne,
            amountIn,
            zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(data)
        );

        amountOut = uint256(-(zeroForOne ? amount1 : amount0));
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

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        IUniswapV3Pool.CallbackData memory extra = abi.decode(
            data,
            (IUniswapV3Pool.CallbackData)
        );

        if (pstTokens[extra.token0] == true)
            amount0 = IPSTToken(extra.token0).transferFee(amount0) + amount0;
        if (pstTokens[extra.token1] == true)
            amount1 = IPSTToken(extra.token1).transferFee(amount1) + amount1;

        IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
        IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
    }

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data_
    ) public {
        SwapCallbackData memory data = abi.decode(data_, (SwapCallbackData));
        (address tokenIn, address tokenOut, ) = data.path.decodeFirstPool();

        bool zeroForOne = tokenIn < tokenOut;

        int256 amount = zeroForOne ? amount0 : amount1;

        if (data.payer == address(this)) {
            IERC20(tokenIn).transfer(msg.sender, uint256(amount));
        } else {
            if (pstTokens[tokenIn] == true)
                amount =
                    (int256)(IPSTToken(tokenIn).transferFee(uint256(amount))) +
                    amount;
            
            IERC20(tokenIn).transferFrom(
                data.payer,
                msg.sender,
                uint256(amount)
            );
        }
    }

    function burn(
        BurnParams memory params
    ) public returns (uint256 amount0, uint256 amount1) {
        StratoSwapFactory factoryContract = StratoSwapFactory(factory);
        if (
            factoryContract.getPoolAddress(
                params.tokenA,
                params.tokenB,
                params.fee
            ) == address(0)
        ) revert("Pool not existed!");
        if (params.tokenA > params.tokenB)
            revert("tokenA address should be higher than tokenB address");

        IUniswapV3Pool pool = getPool(params.tokenA, params.tokenB, params.fee);

        (amount0, amount1) = pool.burn(
            msg.sender,
            params.lowerTick,
            params.upperTick,
            params.liquidity
        );

        emit Burned(amount0, amount1);
    }

    function collect(
        CollectParams memory params
    ) public returns (uint256 amount0, uint256 amount1) {
        StratoSwapFactory factoryContract = StratoSwapFactory(factory);
        if (
            factoryContract.getPoolAddress(
                params.tokenA,
                params.tokenB,
                params.fee
            ) == address(0)
        ) revert("Pool not existed!");
        if (params.tokenA > params.tokenB)
            revert("tokenA address should be higher than tokenB address");

        IUniswapV3Pool pool = getPool(params.tokenA, params.tokenB, params.fee);

        (amount0, amount1) = pool.collect(
            msg.sender,
            params.recipient,
            params.lowerTick,
            params.upperTick,
            params.amount0Desired,
            params.amount1Desired
        );

        emit Collected(amount0, amount1);
    }

    function colletOwnerFee(
        CollectOwnerParams memory params
    ) public returns (uint256 amount0, uint256 amount1) {
        require(owner == msg.sender, "Message sender should be owner");
        StratoSwapFactory factoryContract = StratoSwapFactory(factory);
        if (
            factoryContract.getPoolAddress(
                params.tokenA,
                params.tokenB,
                params.fee
            ) == address(0)
        ) revert("Pool not existed!");
        if (params.tokenA > params.tokenB)
            revert("tokenA address should be higher than tokenB address");

        IUniswapV3Pool pool = getPool(params.tokenA, params.tokenB, params.fee);

        (amount0, amount1) = pool.collectOwnerFee(params.recipient);

        emit Collected(amount0, amount1);
    }
}
