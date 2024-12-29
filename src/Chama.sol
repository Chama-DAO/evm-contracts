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

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert Chama__onlyAdminCanCall();
        }
        _;
    }

    function createChama(address _admin /*, address _members*/ ) external {
        contributions = new Contributions(_admin);
        // add a function to add members to a chama
    }

    function addMemberToChama(address _member, Contributions _contributions) external {}

    function getChamaDetails(string memory _name) external {}

    function removeMemberFromChama(address _member) external onlyAdmin {}

    function updateChamaMetadata(string memory _name) external onlyAdmin {}
}
