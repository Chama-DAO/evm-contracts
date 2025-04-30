// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IContributions} from "./interfaces/IContributions.sol";
import {Loans} from "./Loans.sol";
import {Errors} from "./utils/Errors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Contributions is Loans, Ownable, IContributions {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    address public factoryContract;
    address private chamaAdmin;
    uint256 public epochPeriod = 30 days;
    uint256 public epochEndTime;
    EnumerableSet.AddressSet private members;

    mapping(address member => Member) private memberData;
    mapping(address => bool) private allowedTokens;

    event TokenHasBeenWhitelisted(address token);
    event MemberHasContributed(address indexed member, uint256 amount, uint256 indexed timestamp);
    event memberRemovedFromChama(address member);

    constructor(address _admin, address _token, uint256 _interestRate)
        Ownable(msg.sender)
        Loans(_token, _interestRate)
    {
        members.add(_admin);
        Member memory newMember = Member(_admin, 0, block.timestamp);
        memberData[_admin] = newMember;
        factoryContract = msg.sender;
        chamaAdmin = _admin;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MEMBER_ROLE, CHAMA_ADMIN_ROLE);
        _grantRole(CHAMA_ADMIN_ROLE, msg.sender);
        grantChamaAdminRole(_admin);
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        _checkOwner();
        _;
    }

    modifier onlyChamaFactory() {
        if (msg.sender != factoryContract) {
            revert Errors.Contributions__notFactoryContract();
        }
        _;
    }

    function addContribution(uint256 _amount) external override onlyRole(MEMBER_ROLE) {
        memberToAmountContributed[msg.sender] += _amount;
        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit MemberHasContributed(msg.sender, _amount, block.timestamp);
    }

    function claimRound(uint256 _amount) external nonReentrant onlyRole(MEMBER_ROLE) {
        // Should check whether the member has contributed and also if they are due to claim their round
        // Should also check if the member has any penalties
        // Then allow if all checks pass, allow them to claim their round
        // q should we clear the member's contributions after they claim their round?
        if (_amount == 0) {
            revert Errors.Contributions__zeroAmountProvided();
        }
        if (block.timestamp < epochEndTime) {
            revert Errors.Contributions__epochNotOver();
        }

        uint256 totalContributedAmount = memberToAmountContributed[msg.sender];
        uint256 availableAmt = totalContributedAmount - contrAmtFrozen[msg.sender];

        if (_amount > availableAmt) {
            revert Errors.Contributions__amountNotAvailable(availableAmt);
        }
        totalContributedAmount -= _amount;
        token.safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Whitelist a token to be used for contributions
     * @notice Contract is meant to handle only USDT for now
     */
    function calculatePenalties(address _member) external returns (uint256) {}

    /*//////////////////////////////////////////////////////////////
                              ADMIN ROLES
    //////////////////////////////////////////////////////////////*/

    function addMemberToChama(address _address) external onlyRole(CHAMA_ADMIN_ROLE) {
        // Add a member to the chama
        // Should check if the member is already in the chama
        if (members.contains(_address)) {
            revert Errors.Contributions__memberAlreadyInChama(_address);
        }
        members.add(_address);
        Member memory newMember = Member(_address, 0, block.timestamp);
        memberData[_address] = newMember;
    }

    function changeAdmin(address _newAdmin) external {
        grantChamaAdminRole(_newAdmin);
        renounceRole(CHAMA_ADMIN_ROLE, chamaAdmin);
        chamaAdmin = _newAdmin;
    }

    function changeContributionToken(address _token) external onlyRole(CHAMA_ADMIN_ROLE) {
        if (_token == address(0)) {
            revert Errors.Contributions__zeroAddressProvided();
        }
        if (token.balanceOf(address(this)) > 0) {
            revert Errors.Contributions__tokenBalanceMustBeZero();
        }
        token = IERC20(_token);
        emit TokenHasBeenWhitelisted(_token);
    }

    function setEpochPeriod(uint256 _epochPeriod) external onlyRole(CHAMA_ADMIN_ROLE) {
        epochPeriod = _epochPeriod;
    }

    function removeMemberFromChama(address _member) external onlyRole(CHAMA_ADMIN_ROLE) {
        // Check if _member is a member of the chama
        if (!members.contains(_member)) {
            revert Errors.Contributions__notMemberInChama();
        }
        // remove member from chama
        uint256 memberBalance = memberToAmountContributed[_member];
        if (memberBalance != 0) {
            revert Errors.Contributions__memberShouldHaveZeroBalance(memberBalance);
        }

        delete memberData[_member];
        members.remove(_member);
        // for (uint256 i = 0; i < members.length; i++) {
        //     if (members[i].member == _member) {
        //         members[i] = members[members.length - 1];
        //         members.pop();
        //         break;
        //     }
        // }

        emit memberRemovedFromChama(_member);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _checkOwner() internal view override {
        if (owner() != _msgSender() && _msgSender() != factoryContract) {
            revert Errors.Ownable__OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function grantChamaAdminRole(address _admin) internal {
        _grantRole(CHAMA_ADMIN_ROLE, _admin);
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getMembers() external view returns (address[] memory) {
        return members.values();
    }

    function getAdmin() external view returns (address) {
        return chamaAdmin;
    }

    function getContributionToken() external view returns (address) {
        return address(token);
    }

    function getMemberContributions(address _address) external view returns (Member memory) {
        return memberData[_address];
    }

    function getContributions(address _member) external view returns (uint256) {
        return (memberToAmountContributed[_member]);
    }
}
