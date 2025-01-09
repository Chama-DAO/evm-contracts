// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface IContributions {
    struct memberContribution {
        address member;
        uint256 amount;
        uint256 timestamp;
    }

    function admin() external view returns (address);

    function addContribution(uint256 _amount, address token) external;

    function claimRound(uint256 amount) external;

    function whitelistToken(address token) external;

    function getContributions(address member) external view returns (memberContribution[] memory);

    function calculatePenalties(uint256 amount) external;

    function addMemberToChama(address member) external;

    function changeAdmin(address newAdmin) external;
}
