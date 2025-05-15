// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Chama} from "src/Chama.sol";

contract DeployChama is Script {
    Chama chamaFactory;

    function run() public {
        vm.startBroadcast();
        chamaFactory = new Chama();
        vm.stopBroadcast();
    }
}
