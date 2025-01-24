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
    error Chama__onlyFactoryAdminCanCall();
    error chama__zeroAddressProvided();
    error Chama__onlyChamaAdminCanCall();

    address public factoryAdmin; // The admin of the protocol
    Contributions public contributions;

    mapping(string => address) public chamas;
    mapping(string chamaName => mapping(address chamaAddress => address chamaAdmin)) public chamaAdmin;

    event chamaCreated(address indexed admin, address contributions);

    modifier onlyFactoryAdmin() {
        if (msg.sender != factoryAdmin) {
            revert Chama__onlyFactoryAdminCanCall();
        }
        _;
    }

    modifier onlyChamaAdmin(string memory _name) {
        if (msg.sender != chamaAdmin[_name][address(contributions)] || msg.sender != factoryAdmin) {
            revert Chama__onlyChamaAdminCanCall();
        }
        _;
    }

    function createChama(address _admin, string memory _name) external returns (address) {
        contributions = new Contributions(_admin);
        chamas[_name] = address(contributions);
        chamaAdmin[_name][address(contributions)] = _admin;

        // add a function to add members to a chama

        emit chamaCreated(_admin, address(contributions));
        return address(contributions);
    }

    function addMemberToChama(address _member, string memory _name) external onlyChamaAdmin(_name) {
        if (_member == address(0)) {
            revert chama__zeroAddressProvided();
        }
        Contributions chamaAddress = Contributions(chamas[_name]);
        chamaAddress.addMemberToChama(_member);
    }

    function getChamaDetails(string memory _name) external view returns (address) {
        // get chama details
        address chama = chamas[_name];
        return chama;
    }
}
