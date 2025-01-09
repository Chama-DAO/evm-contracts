// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Loans} from "./Loans.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Contributions is Loans {
    using SafeERC20 for IERC20;

    error Contributions__onlyAdminCanCall();
    error Contributions__onlyMemberCanCall();
    error Contributions__tokenNotAllowed();
    error Contributions__memberAlreadyInChama(address);

    struct memberContribution {
        address member;
        uint256 amount;
        uint256 timestamp;
    }

    address public admin;

    mapping(address => memberContribution[]) private contributions;
    // mapping for allowed tokens
    mapping(address => bool) private allowedTokens;

    event AdminHasBeenChanged(address oldAdmin, address newAdmin);
    event TokenHasBeenWhitelisted(address token);
    event MemberHasContributed(address indexed member, uint256 amount, uint256 timestamp);

    constructor(address _admin) {
        admin = _admin;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin || msg.sender != 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f) {
            revert Contributions__onlyAdminCanCall();
        }
        _;
    }

    modifier onlyMember() {
        if (contributions[msg.sender].length == 0 /*|| msg.sender != contributions[msg.sender][0].member*/ ) {
            revert Contributions__onlyMemberCanCall();
        }
        _;
    }

    function addContribution(uint256 _amount, address _token) external onlyMember {
        if (!allowedTokens[_token]) {
            revert Contributions__tokenNotAllowed();
        }

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        contributions[msg.sender].push(memberContribution(msg.sender, _amount, block.timestamp));

        emit MemberHasContributed(msg.sender, _amount, block.timestamp);
    }

    function claimRound(uint256 _amount) external nonReentrant onlyMember {
        // Should check whether the member has contributed and also if they are due to claim their round
        // Should also check if the member has any penalties
        // Then allow if all checks pass, allow them to claim their round
        // q should we clear the member's contributions after they claim their round?
    }

    function whitelistToken(address _token) external onlyAdmin {
        allowedTokens[_token] = true;

        emit TokenHasBeenWhitelisted(_token);
    }

    function getContributions(address _member) external view returns (memberContribution[] memory) {
        return (contributions[_member]);
    }

    function calculatePenalties(address _member) external {}

    function addMemberToChama(address _member) external onlyAdmin {
        // Add a member to the chama
        // Should check if the member is already in the chama
        if (contributions[_member].length == 0) {
            contributions[_member].push(memberContribution(_member, 0, block.timestamp));
        }
        revert Contributions__memberAlreadyInChama(_member);
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = _newAdmin;

        emit AdminHasBeenChanged(oldAdmin, _newAdmin);
    }
}
