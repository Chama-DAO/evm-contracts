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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "./utils/Errors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Chama is Ownable {
    address public factoryAdmin; // The admin of the protocol
    Contributions public contributions;
    IERC20 defaultToken; // This is meant to be usdt/usdc to be decided later

    mapping(string => address) private chamas;
    mapping(string chamaName => mapping(address chamaAddress => address chamaAdmin))
        public chamaAdmin;

    event chamaCreated(address indexed admin, address contributions);

    constructor() Ownable(msg.sender) {
        factoryAdmin = msg.sender;
    }

    modifier onlyFactoryAdmin() {
        _checkOwner();
        _;
    }

    modifier onlyChamaAdmin(string memory _name) {
        if (
            msg.sender != chamaAdmin[_name][address(contributions)] &&
            msg.sender != factoryAdmin
        ) {
            revert Errors.Chama__onlyChamaAdminCanCall();
        }
        _;
    }

    function createChama(
        address _admin,
        string memory _name
    ) external returns (address) {
        contributions = new Contributions(_admin, address(defaultToken));
        chamas[_name] = address(contributions);
        chamaAdmin[_name][address(contributions)] = _admin;

        // add a function to add members to a chama

        emit chamaCreated(_admin, address(contributions));
        return address(contributions);
    }

    function addMemberToChama(
        address _member,
        string memory _name
    ) external onlyChamaAdmin(_name) {
        if (_member == address(0)) {
            revert Errors.chama__zeroAddressProvided();
        }
        Contributions chamaAddress = Contributions(chamas[_name]);
        chamaAddress.addMemberToChama(_member);
    }

    function getChamaAddress(
        string memory _name
    ) external view returns (address) {
        // get chama details
        address chama = chamas[_name];
        return chama;
    }

    function _checkOwner() internal view override {
        if (owner() != msg.sender) {
            revert Errors.Ownable__OwnableUnauthorizedAccount(msg.sender);
        }
    }
}
