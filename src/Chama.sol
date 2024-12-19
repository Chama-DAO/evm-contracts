// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Contributions} from "./Contributions.sol";

contract Chama {
    error Chama__onlyAdminCanCall();

    address public admin; // The admin of a chama
    Contributions public contributions;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert Chama__onlyAdminCanCall();
        }
        _;
    }

    function createChama(address _admin, address _members) external {
        contributions = new Contributions(admin);
    }

    function addMemberToChama(address _member, Contributions _contributions) external {}

    function getChamaDetails(string memory _name) external {}

    function removeMemberFromChama(address _member) external onlyAdmin {}

    function updateChamaMetadata(string memory _name) external onlyAdmin {}
}
