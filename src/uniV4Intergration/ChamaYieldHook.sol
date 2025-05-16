// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Currency} from "v4-core/src/types/Currency.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// For now we are using morpho vaults, which are ERC4626 compliant
interface ILendingProtocol is IERC4626 {}

import {BaseHook, Hooks, IPoolManager, SwapParams} from "v4-periphery/src/utils/BaseHook.sol";

contract ChamaYieldHook is BaseHook {
    using SafeERC20 for IERC20;
    using PoolIdLibrary for PoolKey;
    // NOTE: ---------------------------------------------------------
    // state variables should typically be unique to a pool
    // a single hook contract should be able to service multiple pools
    // ---------------------------------------------------------------

    mapping(PoolId => uint256 count) public beforeSwapCount;
    mapping(PoolId => uint256 count) public afterSwapCount;
    mapping(address => bool) public approvedYieldProtocols;
    mapping(address => address) public tokenYieldProtocol; //current yield protocols for each token
    // Minimum token balance to keep liquid (not rehypothecated)
    mapping(address => uint256) public minLiquidBalance;
    // Amount of tokens currently deployed in yield protocols
    mapping(address => uint256) public deployed;

    event TokensWithdrawn(address indexed token, address indexed protocol, uint256 amount);
    event TokensDeployed(address indexed token, address indexed protocol, uint256 amount);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function _beforeSwap(address, PoolKey calldata key, SwapParams calldata params, bytes calldata)
        internal
        returns (
            /*override*/
            bytes4,
            BeforeSwapDelta,
            uint24
        )
    {
        // Before a swap, make sure we have enough liquidity by withdrawing from yield protocol if needed
        address tokenOut = params.zeroForOne ? Currency.unwrap(key.currency1) : Currency.unwrap(key.currency0);

        // Ensure enough liquidity for tokenOut
        ensureLiquidity(tokenOut, params.amountSpecified);
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _afterSwap(address, PoolKey calldata key, SwapParams calldata, BalanceDelta delta, bytes calldata hookData)
        internal
        returns (bytes4, int128)
    {
        address token0 = Currency.unwrap(key.currency0);
        address token1 = Currency.unwrap(key.currency1);

        // Check if we can deploy excess liquidity
        deployExcessLiquidity(token0);
        deployExcessLiquidity(token1);
        return (BaseHook.afterSwap.selector, 0);
    }

    function ensureLiquidity(address token, int256 amountNeeded) internal {
        if (amountNeeded <= 0) return;

        uint256 currentBalance = IERC20(token).balanceOf(address(this));

        // If we don't have enough liquid tokens, withdraw from lending protocol
        if (currentBalance < uint256(amountNeeded) && deployed[token] > 0) {
            address yieldProtocol = tokenYieldProtocol[token];

            if (yieldProtocol != address(0)) {
                uint256 amountToWithdraw = uint256(amountNeeded) - currentBalance;
                if (amountToWithdraw > deployed[token]) {
                    amountToWithdraw = deployed[token];
                }

                // Withdraw from lending protocol
                ILendingProtocol(yieldProtocol).withdraw(amountToWithdraw, token, msg.sender);
                deployed[token] -= amountToWithdraw;

                emit TokensWithdrawn(token, yieldProtocol, amountToWithdraw);
            }
        }
    }

    function deployExcessLiquidity(address token) internal {
        address yieldProtocol = tokenYieldProtocol[token];

        if (yieldProtocol != address(0)) {
            uint256 currentBalance = IERC20(token).balanceOf(address(this));
            uint256 excessAmount = 0;

            if (currentBalance > minLiquidBalance[token]) {
                excessAmount = currentBalance - minLiquidBalance[token];

                if (excessAmount > 0) {
                    IERC20(token).safeIncreaseAllowance(yieldProtocol, excessAmount);
                    ILendingProtocol(yieldProtocol).deposit(excessAmount, token);
                    deployed[token] += excessAmount;

                    emit TokensDeployed(token, yieldProtocol, excessAmount);
                }
            }
        }
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }
}
