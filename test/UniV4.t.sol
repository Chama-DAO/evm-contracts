// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";

contract UniV4Test is Test {
    function testAddresses() public {
        address a = makeAddr("goodLord");
        address b = makeAddr("heyThere");

        bool result = a < b ? true : false;

        console.log("Is a less than b: ", result);
    }
}
