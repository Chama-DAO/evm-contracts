// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Loans} from "./Loans.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Contributions is Loans {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Contributions__onlyAdminCanCall();
    error Contributions__onlyMembersCanCall();
    error Contributions__tokenNotWhitelisted();
    error Contributions__memberAlreadyInChama(address);
    error Contributions__zeroAmountProvided();
    error Contributions__tokenBalanceMustBeZero();
    error Contributions__amountThatCanBeWithdrawnIs(uint256);
    error Contributions__notMemberInChama();
    error Contributions__memeberShouldHaveZeroBalance();

    address public admin;
    IERC20 token;
    // mapping to keep track of amount contributed by each member
    mapping(address member => uint256 amount) private memberToAmountContributed;
    // mapping to check if a member is in the chama
    mapping(address caller => bool isMember) private callerToIsMember;
    // mapping for allowed tokens
    mapping(address => bool) private allowedTokens;

    event AdminHasBeenChanged(address oldAdmin, address newAdmin);
    event TokenHasBeenWhitelisted(address token);
    event MemberHasContributed(address indexed member, uint256 amount, uint256 indexed timestamp);

    constructor(address _admin) {
        admin = _admin;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert Contributions__onlyAdminCanCall();
        }
        _;
    }

    modifier onlyMember() {
        if (!callerToIsMember[msg.sender]) {
            revert Contributions__onlyMembersCanCall();
        }
        _;
    }

    function addContribution(uint256 _amount, address _token) external onlyMember {
        if (!allowedTokens[_token]) {
            revert Contributions__tokenNotWhitelisted();
        }
        memberToAmountContributed[msg.sender] += _amount;

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        emit MemberHasContributed(msg.sender, _amount, block.timestamp);
    }

    function claimRound(uint256 _amount) external nonReentrant onlyMember {
        // Should check whether the member has contributed and also if they are due to claim their round
        // Should also check if the member has any penalties
        // Then allow if all checks pass, allow them to claim their round
        // q should we clear the member's contributions after they claim their round?
        if (_amount == 0) {
            revert Contributions__zeroAmountProvided();
        }
        uint256 totalContributedAmount = memberToAmountContributed[msg.sender];
        if (_amount > totalContributedAmount) {
            revert Contributions__amountThatCanBeWithdrawnIs(totalContributedAmount);
        }
        IERC20(token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Whitelist a token to be used for contributions
     * @notice Contract is meant to handle only USDT for now
     */
    function whitelistToken(address _token) external onlyAdmin {
        allowedTokens[_token] = true;
        token = IERC20(_token);
        emit TokenHasBeenWhitelisted(_token);
    }

    function getContributions(address _member) external view returns (uint256) {
        if (!callerToIsMember[_member]) {
            revert Contributions__notMemberInChama();
        }
        return (memberToAmountContributed[_member]);
    }

    function calculatePenalties(address _member) external returns (uint256) {}

    function addMemberToChama(address _address) external onlyAdmin {
        // Add a member to the chama
        // Should check if the member is already in the chama
        if (!callerToIsMember[_address]) {
            callerToIsMember[_address] = true;
        }
        revert Contributions__memberAlreadyInChama(_address);
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = _newAdmin;

        emit AdminHasBeenChanged(oldAdmin, _newAdmin);
    }

    function changeContributionToken(address _token) external onlyAdmin {
        if (token.balanceOf(address(this)) > 0) {
            revert Contributions__tokenBalanceMustBeZero();
        }
        token = IERC20(_token);
        emit TokenHasBeenWhitelisted(_token);
    }

    function removeMemberFromChama(address _member) external onlyAdmin {
        // remove member from chama
        if (callerToIsMember[_member] && memberToAmountContributed[_member] == 0) {
            callerToIsMember[_member] = false;
        }
        revert Contributions__memeberShouldHaveZeroBalance();
    }
}
