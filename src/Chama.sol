// SPDX-License-Identifier: MIT

// Layout of contract:
// Version
// Imports
// Interfaces, libraries, contracts
// Errors
// type declations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions;
// Constructors
// Receive function
// Fallback Function
// External
// Public
// Internal
// Private
// View & Pure functions

pragma solidity 0.8.24;

import {Contributions} from "./Contributions.sol";

contract Chama {
    error Chama__onlyAdminCanCall();

    address public admin; // The admin of the protocol
    Contributions public contributions;

    event chamaCreated(address indexed admin, address contributions);

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert Chama__onlyAdminCanCall();
        }
        _;
    }

    function createChama(address _admin /*, address _members*/ ) external returns (address) {
        contributions = new Contributions(_admin);

        // add a function to add members to a chama

        emit chamaCreated(_admin, address(contributions));
        return address(contributions);
    }

    function addMemberToChama(address _member, Contributions _contributions) external {
        _contributions.addMemberToChama(_member);
    }

    function getChamaDetails(string memory _name) external {
        // get chama details
    }

    function removeMemberFromChama(address _member) external onlyAdmin {}

    function updateChamaMetadata(string memory _name) external onlyAdmin {}
}
