// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

interface IContributions {
    struct Member {
        address member;
        uint256 availableAmount;
        uint256 timestamp;
    }

    function addContribution(uint256 _amount) external;

    function claimRound(uint256 amount) external;

    function getContributions(address member) external view returns (uint256);

    function calculatePenalties(address) external returns (uint256);

    function addMemberToChama(address member) external;

    function changeAdmin(address newAdmin) external;

    function changeContributionToken(address _token) external;

    function getMembers() external view returns (address[] memory);

    function getAdmin() external view returns (address);
}
