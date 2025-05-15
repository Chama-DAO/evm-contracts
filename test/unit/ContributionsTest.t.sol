// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {Contributions} from "src/Contributions.sol";
import {Usdt} from "test/mocks/Usdt.sol";
import {Errors} from "src/utils/Errors.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ContributionsTest is Test {
    Contributions contributions;
    Usdt usdt;

    address admin = makeAddr("admin");
    address member1 = makeAddr("member1");
    address member2 = makeAddr("member2");
    address member3 = makeAddr("member3");
    address attacker = makeAddr("attacker");

    function setUp() external {
        usdt = new Usdt();
        contributions = new Contributions(admin, address(usdt), 10);
        usdt.mint(admin, 100);
        usdt.mint(member1, 100);
        usdt.mint(member2, 100);
        usdt.mint(member3, 100);
        usdt.mint(attacker, 100);

        vm.startPrank(admin);
        contributions.addMemberToChama(member1);
        contributions.addMemberToChama(member2);
        contributions.addMemberToChama(member3);
        vm.stopPrank();

        vm.prank(member1);
        Usdt(usdt).approve(address(contributions), 100);
        vm.prank(member2);
        Usdt(usdt).approve(address(contributions), 100);
        vm.prank(member3);
        Usdt(usdt).approve(address(contributions), 100);
    }

    function testNonMembersCannotContribute() external {
        vm.prank(attacker);
        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        contributions.addContribution(1);
    }

    function testMembersCanContribute() external {
        for (uint256 i = 0; i <= 2; i++) {
            if (i == 0) {
                vm.startPrank(member1);
            } else if (i == 1) {
                vm.startPrank(member2);
            } else {
                vm.startPrank(member3);
            }
            contributions.addContribution(10);
        }
        vm.stopPrank();
        assertEq(usdt.balanceOf(address(contributions)), 30);
        assertEq(contributions.getContributions(member1), 10);
    }

    function testOnlyAdminCanChangeToken() external {
        vm.prank(member1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, member1, keccak256("CHAMA_ADMIN_ROLE")
            )
        );
        contributions.changeContributionToken(address(usdt));
    }

    function testTokenCantChangeWithActiveBalance() external {
        vm.startPrank(member1);
        contributions.addContribution(10);
        vm.stopPrank();
        vm.prank(admin);
        vm.expectRevert(Errors.Contributions__tokenBalanceMustBeZero.selector);
        contributions.changeContributionToken(address(usdt));
    }

    function testChangeContributionTokenZeroAddress() external {
        vm.prank(admin);
        vm.expectRevert(Errors.Contributions__zeroAddressProvided.selector);
        contributions.changeContributionToken(address(0));
    }

    function testCanChangeContributiontoken() external {
        Usdt otherToken = new Usdt();
        vm.prank(admin);
        contributions.changeContributionToken(address(otherToken));
        assertEq(address(otherToken), address(contributions.getContributionToken()));
    }

    function testUsersCannotRemoveMemberFromChama() external {
        vm.prank(member1);
        vm.expectPartialRevert(IAccessControl.AccessControlUnauthorizedAccount.selector);
        contributions.removeMemberFromChama(member1);
    }

    function testMembersWithbalanceCannotBeRemoved() external {
        vm.startPrank(member1);
        contributions.addContribution(10);
        vm.stopPrank();
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(Errors.Contributions__memberShouldHaveZeroBalance.selector, 10));
        contributions.removeMemberFromChama(member1);
    }

    function testMembersCanBeRemoved() external {
        vm.prank(admin);
        contributions.removeMemberFromChama(member1);
        assertEq(contributions.getMembers().length, 3);
    }

    function testBurn() external {
        // Not significant since its just test tokens
        vm.prank(member1);
        usdt.burn(member1, 10);
    }

    function testChangeAdmin() external {
        vm.prank(admin);
        contributions.changeAdmin(attacker);
        assertEq(contributions.getAdmin(), attacker);
    }
}
