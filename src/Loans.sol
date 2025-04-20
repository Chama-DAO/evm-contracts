// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Errors} from "./utils/Errors.sol";

// handle the loans for a chama
contract Loans is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    // We are going to use USDC by default
    IERC20 internal token;
    uint256 internal interestRate;

    uint256 internal constant BASIS_POINTS = 10000;

    bytes32 internal constant MEMBER_ROLE = keccak256("MEMBER_ROLE");
    bytes32 internal constant CHAMA_ADMIN_ROLE = keccak256("CHAMA_ADMIN_ROLE");

    mapping(address member => uint256 amount) internal contrAmtFrozen;
    mapping(address member => uint256 amount) internal loanAmtAvailable;
    mapping(address member => uint256 amount) internal memberToAmountContributed;

    constructor(address _token, uint256 _interestRate) {
        token = IERC20(_token);
        if (_interestRate > BASIS_POINTS) revert Errors.Loans_invalidInterestRate(BASIS_POINTS, _interestRate);
        interestRate = _interestRate;
    }

    function guaranteeLoan(address _member, uint256 _amount) external onlyRole(MEMBER_ROLE) {
        if (memberToAmountContributed[_member] < _amount) {
            revert Errors.Loans__contrAmtLessLoanAmt(memberToAmountContributed[_member], _amount);
        }
        contrAmtFrozen[msg.sender] += _amount;
        loanAmtAvailable[_member] += _amount;
    }

    function takeLoan(uint256 _amount) external onlyRole(MEMBER_ROLE) nonReentrant {
        if (_amount > contrAmtFrozen[msg.sender]) {
            revert Errors.Loans__loanAmtGreaterThanGuaranteedAmt(_amount, loanAmtAvailable[msg.sender]);
        }
        loanAmtAvailable[msg.sender] -= _amount;
        token.safeTransfer(msg.sender, _amount);
    }

    function repayLoan(uint256 _amount) external onlyRole(MEMBER_ROLE) nonReentrant {
        // Calculate Interest Rate
        // add some more logic and checks here
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }
}
