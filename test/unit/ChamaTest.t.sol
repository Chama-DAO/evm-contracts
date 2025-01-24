// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IContributions} from "../../src/interfaces/IContributions.sol";
import {Chama} from "src/Chama.sol";

contract ChamaTest is Test {
    Chama chama;

    address protocolAdmin = makeAddr("protocolAdmin");
    address chamaAdmin = makeAddr("chamaAdmin");

    function setUp() external {
        chama = new Chama();
    }

    function testCreateChama() external {
        address contributions = chama.createChama(chamaAdmin, "Chama1");

        console.log("Chama admin is: ", IContributions(contributions).admin());

        assertEq(IContributions(contributions).admin(), chamaAdmin);
    }
}
