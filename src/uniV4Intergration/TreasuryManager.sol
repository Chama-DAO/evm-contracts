// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Errors} from "../utils/Errors.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
// Swap
import {UniversalRouter} from "@uniswap/universal-router/contracts/UniversalRouter.sol";
import {Commands} from "@uniswap/universal-router/contracts/libraries/Commands.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {IV4Router, PoolKey, Currency} from "v4-periphery/src/interfaces/IV4Router.sol";
import {Actions} from "v4-periphery/src/libraries/Actions.sol";
import {IPermit2} from "@uniswap/permit2/src/interfaces/IPermit2.sol";

contract TreasuryManager is AccessControl {
    using SafeERC20 for IERC20;
    using StateLibrary for IPoolManager;

    bytes32 public constant TREASURY_ADMIN_ROLE = keccak256("TREASURY_ADMIN_ROLE");
    bytes32 public constant CHAMA_ROLE = keccak256("CHAMA_ROLE");

    IPositionManager posm;

    UniversalRouter public immutable router;
    IPoolManager public immutable poolManager;
    IPermit2 public immutable permit2;

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

    constructor(
        address _poolManager,
        address _usdcToken,
        address _admin,
        IPositionManager _posm,
        address _router,
        address _permit2
    ) {
        router = UniversalRouter(payable(_router));
        poolManager = IPoolManager(_poolManager);
        permit2 = IPermit2(_permit2);
        usdcToken = _usdcToken;
        posm = _posm;

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

    function swapTokens(
        PoolKey memory key,
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint128 minAmountOut,
        address recipient
    ) external onlyRole(CHAMA_ROLE) returns (uint256 amountOut) {
        // TODO: Implement swap logic using Uniswap v4 PoolSwapTest
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(router), amountIn);

        // Execute swap through Uniswap v4
        // Placeholder for actual Uniswap v4 swap logic
        amountOut = executeSwap(key, amountIn, minAmountOut);

        require(amountOut >= minAmountOut, "Slippage too high");

        IERC20(tokenOut).safeTransfer(recipient, amountOut);

        emit SwapExecuted(tokenIn, tokenOut, amountIn, amountOut);
        return amountOut;
    }

    function approveTokenWithPermit2(address token, uint160 amount, uint48 expiration) external {
        IERC20(token).approve(address(permit2), type(uint256).max);
        permit2.approve(token, address(router), amount, expiration);
    }

    function executeSwap(PoolKey memory key, uint128 amountIn, uint128 minAmountOut)
        public
        returns (uint256 amountOut)
    {
        bytes memory commands = abi.encodePacked(uint8(Commands.V4_SWAP));
        bytes[] memory inputs = new bytes[](1);

        bytes memory actions =
            abi.encodePacked(uint8(Actions.SWAP_EXACT_IN_SINGLE), uint8(Actions.SETTLE_ALL), uint8(Actions.TAKE_ALL));

        bytes[] memory params = new bytes[](3);
        params[0] = abi.encode(
            IV4Router.ExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                hookData: bytes("")
            })
        );
        params[1] = abi.encode(key.currency0, amountIn);
        params[2] = abi.encode(key.currency1, minAmountOut);

        inputs[0] = abi.encode(actions, params);

        // Execute the swap
        uint256 deadline = block.timestamp + 20;
        router.execute(commands, inputs, deadline);

        // Verify and return the output amount
        amountOut = IERC20(Currency.unwrap(key.currency1)).balanceOf(address(this));
        require(amountOut >= minAmountOut, "Insufficient output amount");
        return amountOut;
    }

    // Need to implement a way to repay users any excess tokens that remain in the protocol
    function addLiquidity(
        uint256 tokenId,
        uint256 liquidity,
        address token0,
        address token1,
        uint256 amount0Max,
        uint256 amount1Max,
        bytes calldata hookData
    ) external onlyRole(TREASURY_ADMIN_ROLE) returns (uint256 positionId) {
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0Max);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1Max);

        IERC20(token0).approve(address(posm), amount0Max);
        IERC20(token1).approve(address(posm), amount1Max);

        bytes memory actions = abi.encodePacked(uint8(Actions.INCREASE_LIQUIDITY), uint8(Actions.SETTLE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(tokenId, liquidity, amount0Max, amount1Max, hookData);
        Currency currency0 = Currency.wrap(token0);
        Currency currency1 = Currency.wrap(token1);
        params[1] = abi.encode(currency0, currency1);

        uint256 deadline = block.timestamp + 60;

        uint256 valueToPass = currency0.isAddressZero() ? amount0Max : 0;

        posm.modifyLiquidities{value: valueToPass}(abi.encode(actions, params), deadline);

        emit LiquidityAdded(token0, token1, amount0Max, amount1Max);
        return 0;
    }

    function removeLiquidity(
        uint256 tokenId,
        uint256 liquidity,
        address token0,
        address token1,
        uint256 amount0Min,
        uint256 amount1Min,
        bytes calldata hookData
    ) external onlyRole(TREASURY_ADMIN_ROLE) {
        bytes memory actions = abi.encodePacked(uint8(Actions.DECREASE_LIQUIDITY), uint8(Actions.TAKE_PAIR));

        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(tokenId, liquidity, amount0Min, amount1Min, hookData);
        Currency currency0 = Currency.wrap(token0);
        Currency currency1 = Currency.wrap(token1);
        params[1] = abi.encode(currency0, currency1, msg.sender);

        uint256 deadline = block.timestamp + 60;

        uint256 valueToPass = currency0.isAddressZero() ? amount0Min : 0;

        posm.modifyLiquidities{value: valueToPass}(abi.encode(actions, params), deadline);
    }

    /// TODO: Add a way for identifying which tokens were collected
    function collectPoolFees(uint256 tokenId, bytes memory hookData, address token0, address token1) external {
        bytes memory actions = abi.encodePacked(uint8(Actions.DECREASE_LIQUIDITY), uint8(Actions.TAKE_PAIR));

        bytes[] memory params = new bytes[](2);
        /// @dev collecting fees is achieved with liquidity=0, the second parameter
        params[0] = abi.encode(tokenId, 0, 0, 0, hookData);

        Currency currency0 = Currency.wrap(token0);
        Currency currency1 = Currency.wrap(token1);
        params[1] = abi.encode(currency0, currency1, msg.sender);

        uint256 deadline = block.timestamp + 60;

        uint256 valueToPass = currency0.isAddressZero() ? 0 : 0;

        posm.modifyLiquidities{value: valueToPass}(abi.encode(actions, params), deadline);
    }

    // Deposit unused assets into yield-generating protocol
    // For now we are going to use mopho vaults
    function depositIntoYieldProtocol(address token, uint256 amount, address yieldProtocol)
        external
        onlyRole(TREASURY_ADMIN_ROLE)
    {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        // TODO
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
