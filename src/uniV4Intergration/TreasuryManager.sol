// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolManager, IPoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {PoolModifyLiquidityTest} from "@uniswap/v4-core/src/test/PoolModifyLiquidityTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Errors} from "../utils/Errors.sol";

contract TreasuryManager is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant TREASURY_ADMIN_ROLE = keccak256("TREASURY_ADMIN_ROLE");
    bytes32 public constant CHAMA_ROLE = keccak256("CHAMA_ROLE");

    PoolManager public immutable poolManager;
    PoolModifyLiquidityTest public immutable modifyPositionRouter;
    PoolSwapTest public immutable swapRouter;

    address public immutable usdcToken;

    mapping(address => mapping(address => uint256)) public poolIds;

    // Protocol fees in basis points
    uint256 public baseFee = 30; // 0.3%
    uint256 public stablecoinReducedFee = 10; // 0.1% for stablecoin swaps

    // Yield strategy settings
    address public currentYieldProtocol;
    bool public autoReinvestYield = true;

    event SwapExecuted(address indexed token0, address indexed token1, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed token0, address indexed token1, uint256 amount0, uint256 amount1);
    event YieldDeposited(address indexed protocol, address indexed token, uint256 amount);
    event FeesCollected(address indexed token, uint256 amount);

    constructor(address _poolManager, address _usdcToken, address _admin) {
        poolManager = PoolManager(_poolManager);
        modifyPositionRouter = new PoolModifyLiquidityTest(IPoolManager(_poolManager));
        swapRouter = new PoolSwapTest(IPoolManager(_poolManager));
        usdcToken = _usdcToken;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(TREASURY_ADMIN_ROLE, _admin);
    }

    function getDynamicFee(address token0, address token1) public view returns (uint256) {
        // If both tokens are stablecoins, apply reduced fee
        if (isStablecoin(token0) && isStablecoin(token1)) {
            return stablecoinReducedFee;
        }

        return baseFee;
    }

    function isStablecoin(address token) public view returns (bool) {
        // TODO Add logic to identify stablecoins (USDC, USDT, DAI, etc.)
        // For now, using a simple check for USDC
        return token == usdcToken;
    }

    function swapTokens(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address recipient)
        external
        onlyRole(CHAMA_ROLE)
        returns (uint256 amountOut)
    {
        // TODO: Implement swap logic using Uniswap v4 PoolSwapTest
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(swapRouter), amountIn);

        // Execute swap through Uniswap v4
        // Placeholder for actual Uniswap v4 swap logic
        amountOut = executeSwap(tokenIn, tokenOut, amountIn);

        require(amountOut >= minAmountOut, "Slippage too high");

        IERC20(tokenOut).safeTransfer(recipient, amountOut);

        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut);
        return amountOut;
    }

    // Placeholder for swap execution (to be implemented with actual Uniswap v4 calls)
    function executeSwap(address tokenIn, address tokenOut, uint256 amountIn) internal returns (uint256) {
        // TODO: implement actual Uniswap v4 swap logic here
        // This is just a placeholder for now
        return amountIn;
    }

    // Add liquidity to Uniswap v4 pool, Remember to add the logic to add the liquidity to actual uniswap v4 pools
    function addLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        int24 tickLower,
        int24 tickUpper
    ) external onlyRole(TREASURY_ADMIN_ROLE) returns (uint256 positionId) {
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        IERC20(token0).approve(address(modifyPositionRouter), amount0);
        IERC20(token1).approve(address(modifyPositionRouter), amount1);

        // Placeholder for actual Uniswap v4 liquidity addition
        // This would call the modifyPositionRouter with the correct parameters

        emit LiquidityAdded(token0, token1, amount0, amount1);
        return 0;
    }

    // Deposit unused assets into yield-generating protocol
    function depositIntoYieldProtocol(address token, uint256 amount, address yieldProtocol)
        external
        onlyRole(TREASURY_ADMIN_ROLE)
    {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Placeholder for yield protocol deposit logic
        // This would integrate with lending protocols on Base

        currentYieldProtocol = yieldProtocol;

        emit YieldDeposited(yieldProtocol, token, amount);
    }

    // Update fee parameters (only admin)
    function updateFeeParameters(uint256 _baseFee, uint256 _stablecoinReducedFee)
        external
        onlyRole(TREASURY_ADMIN_ROLE)
    {
        require(_baseFee <= 100, "Fee too high"); // Max 1%
        require(_stablecoinReducedFee <= _baseFee, "Reduced fee must be <= base fee");

        baseFee = _baseFee;
        stablecoinReducedFee = _stablecoinReducedFee;
    }

    // Grant CHAMA_ROLE to a Chama contract
    function addChamaContract(address chamaContract) external onlyRole(TREASURY_ADMIN_ROLE) {
        _grantRole(CHAMA_ROLE, chamaContract);
    }
}
