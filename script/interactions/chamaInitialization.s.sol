// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {IContributions} from "src/interfaces/IContributions.sol";
import {Contributions} from "src/Contributions.sol";
import {Constants} from "script/Constants.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChamaInitialization is Script {
    using SafeERC20 for IERC20;

    address[] members = new address[](5);
    bytes32 internal constant MEMBER_ROLE = keccak256("MEMBER_ROLE");
    bytes32 internal constant CHAMA_ADMIN_ROLE = keccak256("CHAMA_ADMIN_ROLE");

    constructor() {
        members[0] = address(0x100);
        members[1] = address(0x200);
        members[2] = address(0xdead);
        members[3] = address(0xbeef);
        members[4] = address(58765433456);
    }

    function run() public {
        // setChamaEpoachPeriod(10 minutes);
        // addMembers(members);
        // removeMembers(members);
        // changeContributionToken(Constants.testUsdc);
        // grantMemberRole(Constants.me);
        makeContribution(1e6);
        // repayLoan(1e6, 0, Constants.me);
        // revokeMemberRole(members);
    }

    function setChamaEpoachPeriod(uint256 _epochPeriod) public {
        vm.broadcast();
        Contributions(Constants.chamaContributions).setEpochPeriod(_epochPeriod);
    }

    function addMembers(address[] memory _members) public {
        vm.startBroadcast();
        for (uint256 i = 0; i < _members.length; i++) {
            Contributions(Constants.chamaContributions).addMemberToChama(_members[i]);
        }
        vm.stopBroadcast();
    }

    function removeMembers(address[] memory _members) public {
        vm.startBroadcast();
        for (uint256 i = 0; i < _members.length; i++) {
            Contributions(Constants.chamaContributions).removeMemberFromChama(_members[i]);
        }
        vm.stopBroadcast();
    }

    function makeContribution(uint256 _amount) public {
        vm.startBroadcast();
        IERC20(Constants.testUsdc).forceApprove(address(Constants.chamaContributions), _amount);
        Contributions(Constants.chamaContributions).addContribution(_amount);
        vm.stopBroadcast();
    }

    function grantMemberRole(address _member) public {
        vm.startBroadcast();
        Contributions(Constants.chamaContributions).grantRole(MEMBER_ROLE, _member);
        vm.stopBroadcast();
    }

    function revokeMemberRole(address[] memory _members) public {
        vm.startBroadcast();
        for (uint256 i = 0; i < _members.length; i++) {
            Contributions(Constants.chamaContributions).revokeRole(MEMBER_ROLE, _members[i]);
        }
        vm.stopBroadcast();
    }

    function changeContributionToken(address _token) public {
        vm.startBroadcast();
        Contributions(Constants.chamaContributions).changeContributionToken(_token);
        vm.stopBroadcast();
    }

    function repayLoan(uint256 _amount, uint256 _loanId, address _guarantor) public {
        vm.startBroadcast();
        Contributions(Constants.chamaContributions).repayLoan(_amount, _loanId, _guarantor);
        vm.stopBroadcast();
    }
}
