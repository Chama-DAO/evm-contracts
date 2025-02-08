// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Loans} from "./Loans.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "./utils/Errors.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IContributions} from "./interfaces/IContributions.sol";

contract Contributions is Loans, Ownable, IContributions {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    Member[] public members;

    address private admin;
    address public factoryContract;
    IERC20 token;

    // mapping to keep track of amount contributed by each member
    mapping(address member => uint256 amount) private memberToAmountContributed;
    // mapping to check if a member is in the chama
    mapping(address caller => bool isMember) callerToIsMember;
    // mapping for allowed tokens
    mapping(address => bool) private allowedTokens;

    event AdminHasBeenChanged(address oldAdmin, address newAdmin);
    event TokenHasBeenWhitelisted(address token);
    event MemberHasContributed(address indexed member, uint256 amount, uint256 indexed timestamp);

    constructor(address _admin) Ownable(_admin) {
        callerToIsMember[_admin] = true;
        factoryContract = msg.sender;
    }
    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        _checkOwner();
        _;
    }

    modifier onlyMember() {
        if (!callerToIsMember[msg.sender]) {
            revert Errors.Contributions__onlyMembersCanCall();
        }
        _;
    }

    function addContribution(uint256 _amount) external override onlyMember {
        memberToAmountContributed[msg.sender] += _amount;
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

        emit MemberHasContributed(msg.sender, _amount, block.timestamp);
    }

    function claimRound(uint256 _amount) external nonReentrant onlyMember {
        // Should check whether the member has contributed and also if they are due to claim their round
        // Should also check if the member has any penalties
        // Then allow if all checks pass, allow them to claim their round
        // q should we clear the member's contributions after they claim their round?
        if (_amount == 0) {
            revert Errors.Contributions__zeroAmountProvided();
        }
        uint256 totalContributedAmount = memberToAmountContributed[msg.sender];
        if (_amount > totalContributedAmount) {
            revert Errors.Contributions__amountThatCanBeWithdrawnIs(totalContributedAmount);
        }
        IERC20(token).safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Whitelist a token to be used for contributions
     * @notice Contract is meant to handle only USDT for now
     */
    function getContributions(address _member) external view returns (uint256) {
        if (!callerToIsMember[_member]) {
            revert Errors.Contributions__notMemberInChama();
        }
        return (memberToAmountContributed[_member]);
    }

    function calculatePenalties(address _member) external returns (uint256) {}

    function addMemberToChama(address _address) external onlyAdmin {
        // Add a member to the chama
        // Should check if the member is already in the chama
        if (callerToIsMember[_address]) {
            revert Errors.Contributions__memberAlreadyInChama(_address);
        }
        Member memory newMember = Member(_address, 0, block.timestamp);
        members.push(newMember);
        callerToIsMember[_address] = true;
    }

    function changeAdmin(address _newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = _newAdmin;

        emit AdminHasBeenChanged(oldAdmin, _newAdmin);
    }

    function changeContributionToken(address _token) external onlyAdmin {
        if (token.balanceOf(address(this)) > 0) {
            revert Errors.Contributions__tokenBalanceMustBeZero();
        }
        token = IERC20(_token);
        emit TokenHasBeenWhitelisted(_token);
    }

    function removeMemberFromChama(address _member) external onlyAdmin {
        // remove member from chama
        if (callerToIsMember[_member] && memberToAmountContributed[_member] == 0) {
            delete callerToIsMember[_member];
        }
        revert Errors.Contributions__memeberShouldHaveZeroBalance();
    }
    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _checkOwner() internal view override {
        if (owner() != _msgSender() && _msgSender() != factoryContract) {
            revert Errors.Ownable__OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function getMembers() external view override returns (Member[] memory) {
        return members;
    }

    function getAdmin() external view returns (address) {
        return admin;
    }
}
