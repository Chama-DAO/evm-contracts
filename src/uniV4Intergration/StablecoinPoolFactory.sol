// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {IPoolInitializer_v4} from "v4-periphery/src/interfaces/IPoolInitializer_v4.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {ChamaFeeHook} from "./ChamaFeeHook.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Errors} from "../utils/Errors.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {IAllowanceTransfer} from "v4-periphery/lib/permit2/src/interfaces/IAllowanceTransfer.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LPFeeLibrary} from "v4-core/src/libraries/LPFeeLibrary.sol";

contract StablecoinPoolFactory is AccessControl {
    bytes32 public constant POOL_CREATOR_ROLE = keccak256("POOL_CREATOR_ROLE");

    IPoolManager public immutable poolManager;
    ChamaFeeHook public immutable feeHook;
    address public immutable usdcToken;
    IPositionManager posm;

    // Mapping to track created pools
    mapping(address token => bool exists) public createdPools;

    event PoolCreated(address indexed token, int24 tickSpacing);

    constructor(
        IPoolManager _poolManager,
        IPositionManager _positionManager,
        ChamaFeeHook _feeHook,
        address _usdcToken,
        address _admin
    ) {
        poolManager = _poolManager;
        feeHook = _feeHook;
        usdcToken = _usdcToken;
        posm = _positionManager;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(POOL_CREATOR_ROLE, _admin);
    }

    /**
     *
     * @notice This creates a new USDC pair with optimized parameters for stablecoins
     * @param token This is the other token for the pool
     * @param tickSpacing is the granularity of the pool. Lower values are more precise but may be more expensive to trade on
     * @param sqrtPriceX96 should be expressed as floor(sqrt(token1 / token0) * 2^96)
     */
    function createStablecoinPool(address token, int24 tickSpacing, uint160 sqrtPriceX96)
        external
        onlyRole(POOL_CREATOR_ROLE)
    {
        _createStablecoinPool(token, tickSpacing, sqrtPriceX96);
    }

    /// See createStablecoinPool for details, only change with this is that we are doing pools for multiple tokens at once
    /// @param initialPrices should be expressed as floor(sqrt(token1 / token0) * 2^96)
    function createMultiplePools(
        address[] calldata tokens,
        int24[] calldata tickSpacings,
        uint160[] calldata initialPrices
    ) external onlyRole(POOL_CREATOR_ROLE) {
        if (tokens.length != tickSpacings.length && tickSpacings.length != initialPrices.length) {
            revert Errors.PoolFactory__ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < tokens.length; i++) {
            _createStablecoinPool(tokens[i], tickSpacings[i], initialPrices[i]);
        }
    }

    function _createStablecoinPool(address token, int24 tickSpacing, uint160 sqrtPriceX96) internal {
        if (createdPools[token]) revert Errors.PoolFactory__PoolAlreadyExists(token);

        (Currency currency0, Currency currency1) = uint160(usdcToken) < uint160(token)
            ? (Currency.wrap(usdcToken), Currency.wrap(token))
            : (Currency.wrap(token), Currency.wrap(usdcToken));

        PoolKey memory poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: tickSpacing,
            hooks: IHooks(address(feeHook))
        });

        poolManager.initialize(poolKey, sqrtPriceX96);

        createdPools[token] = true;

        emit PoolCreated(token, tickSpacing);
    }

    /// @notice startingPrice is the price of the pool at initialization expressed as floor(sqrt(token1 / token0) * 2^96)
    function createPoolAndAddLiquidity(
        address token,
        int24 tickSpacing,
        uint160 startingPrice,
        int24 tickLower,
        int24 tickUpper,
        uint256 liquidity,
        uint256 amount0Max,
        uint256 amount1Max,
        address recipient,
        bytes calldata hookData,
        address permit2
    ) external {
        bytes[] memory params = new bytes[](2);

        (Currency currency0, Currency currency1) = uint160(usdcToken) < uint160(token)
            ? (Currency.wrap(usdcToken), Currency.wrap(token))
            : (Currency.wrap(token), Currency.wrap(usdcToken));

        PoolKey memory pool = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: tickSpacing,
            hooks: IHooks(address(feeHook))
        });

        params[0] = abi.encodeWithSelector(IPoolInitializer_v4.initializePool.selector, pool, startingPrice);

        bytes memory actions = abi.encodePacked(uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR));

        bytes[] memory mintParams = new bytes[](2);
        mintParams[0] = abi.encode(pool, tickLower, tickUpper, liquidity, amount0Max, amount1Max, recipient, hookData);
        mintParams[1] = abi.encode(pool.currency0, pool.currency1);

        uint256 deadline = block.timestamp + 60;
        params[1] = abi.encodeWithSelector(posm.modifyLiquidities.selector, abi.encode(actions, mintParams), deadline);

        // approve permit2 as a spender
        IERC20(token).approve(address(permit2), type(uint256).max);

        // approve `PositionManager` as a spender
        IAllowanceTransfer(address(permit2)).approve(token, address(posm), type(uint160).max, type(uint48).max);

        IPositionManager(posm).multicall(params);

        uint256 ethTosend = currency0.isAddressZero() ? amount0Max : 0;
        if (ethTosend > 0) IPositionManager(posm).multicall{value: ethTosend}(params);
    }
}
