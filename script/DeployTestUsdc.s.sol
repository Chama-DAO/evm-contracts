// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Usdc} from "test/mocks/Usdc.sol";

contract DeployUsdc is Script {
    Usdc testUsdc;

    function run() public {
        vm.startBroadcast();
        testUsdc = new Usdc();
        testUsdc.mint(msg.sender, 1000e6);
        vm.stopBroadcast();
    }
}
