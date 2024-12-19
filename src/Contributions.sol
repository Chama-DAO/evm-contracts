// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

contract Contributions {
    struct memberContributions {
        address member;
        uint256 amount;
        uint256 timestamp;
    }

    constructor(address _admin) {}

    function addContribution() external {}

    function getContributions(address _member) external returns (address, uint256) {}

    function calculatePenalties(address _member) external {}
}
