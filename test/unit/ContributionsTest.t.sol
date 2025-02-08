// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Contributions} from "src/Contributions.sol";
import {Usdt} from "test/mocks/Usdt.sol";

contract ContributionsTest is Test {
    Contributions contributions;
    Usdt usdt;

    address admin = makeAddr("admin");
    address member1 = makeAddr("member1");
    address member2 = makeAddr("member2");
    address member3 = makeAddr("member3");
    address attacker = makeAddr("attacker");

    function setUp() external {
        contributions = new Contributions(admin);
        usdt = new Usdt();
        usdt.mint(admin, 100);
        usdt.mint(member1, 100);
        usdt.mint(member2, 100);
        usdt.mint(member3, 100);
        usdt.mint(attacker, 100);
    }

    function testNonMembersCannotContribute() external {
        vm.prank(attacker);
        vm.expectRevert();
        contributions.addContribution(1);
    }
}
