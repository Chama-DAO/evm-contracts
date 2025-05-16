// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";

contract ChamaFeeHook {
    uint256 public baseFee = 30; // 0.3%
    uint256 public stablecoinReducedFee = 10; // 0.1% for stablecoin swaps

    mapping(PoolId => uint24) public customFees;
    mapping(address => bool) public isStablecoin;

    constructor() {
        // These are placeholders, for now
        isStablecoin[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // USDC
        isStablecoin[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; // USDT
        isStablecoin[0x6B175474E89094C44Da98b954EedeAC495271d0F] = true; // DAI
    }

    function getDynamicFee(address token0, address token1) public view returns (uint256) {
        // If both tokens are stablecoins, apply reduced fee
        if (isStablecoin[token0] && isStablecoin[token1]) {
            return stablecoinReducedFee;
        }

        return baseFee;
    }

    /// TODO Add some access control on this
    function updateFeeParameters(uint256 _baseFee, uint256 _stablecoinReducedFee) external {
        require(_baseFee <= 100, "Fee too high"); // Max 1%
        require(_stablecoinReducedFee <= _baseFee, "Reduced fee must be <= base fee");

        baseFee = _baseFee;
        stablecoinReducedFee = _stablecoinReducedFee;
    }

    function setStablecoin(address token, bool status) external {
        isStablecoin[token] = status;
    }
}
