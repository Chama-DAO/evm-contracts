// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {IContributions} from "../../src/interfaces/IContributions.sol";
import {Chama} from "src/Chama.sol";

contract ChamaTest is Test {
    Chama chama;

    address protocolAdmin = makeAddr("protocolAdmin");
    address chamaAdmin = makeAddr("chamaAdmin");
    address contributions;

    function setUp() external {
        chama = new Chama();
        contributions = chama.createChama(chamaAdmin, "Chama1", 10);
    }

    function testCreateChama() external {
        vm.prank(chamaAdmin);
        address _contributions = chama.createChama(chamaAdmin, "Chama1", 10);

        console.log("Chama admin is: ", IContributions(_contributions).getAdmin());

        assertEq(IContributions(_contributions).getAdmin(), chamaAdmin);
    }

    function testAddMembersToChama() external {
        address[] memory members = new address[](3);
        members[0] = makeAddr("member1");
        members[1] = makeAddr("member2");
        members[2] = makeAddr("member3");
        vm.startPrank(chamaAdmin);
        for (uint256 i = 0; i <= 2; i++) {
            chama.addMemberToChama(members[i], "Chama1");
        }
        vm.stopPrank();
        address _contributions = chama.getChamaAddress("Chama1");
        address[] memory membersList = IContributions(_contributions).getMembers();
        // Members will be 4 because of chama admin
        assertEq(membersList.length, 4);
    }
}
