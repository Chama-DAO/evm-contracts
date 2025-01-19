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
    error chama__zeroAddressProvided();

    address public admin; // The admin of the protocol
    Contributions public contributions;

    mapping (string => address) public chamas;

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

    function addMemberToChama(address _member, address _contributions) external {
        if(_member == address(0) || _contributions == address(0)) {
            revert chama__zeroAddressProvided();
        }
        Contributions chamaAddress = Contributions(_contributions);
        chamaAddress.addMemberToChama(_member);
    }

    function getChamaDetails(string memory _name) external view returns (address){
        // get chama details
        address chama = chamas[_name];
        return chama;
    }

    function removeMemberFromChama(address _member) external onlyAdmin {
        // remove member from chama
        
    }

    function updateChamaMetadata(string memory _name) external onlyAdmin {}
}
