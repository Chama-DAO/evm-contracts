// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Chama} from "src/Chama.sol";
import {Constants} from "script/Constants.sol";

contract DeployChama is Script {
    Chama chamaFactory;

    function run() public {
        vm.startBroadcast();
        chamaFactory = new Chama();
        setDefaultToken(Constants.testUsdc);
        deployChama(Constants.me, "Chama", 1000);

        vm.stopBroadcast();
    }

    function setDefaultToken(address _address) public {
        chamaFactory.setDefaultToken(_address);
    }

    function deployChama(address _admin, string memory _name, uint256 _interestRate) public {
        chamaFactory.createChama(_admin, _name, _interestRate);
    }
}
