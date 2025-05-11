// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "./utils/Errors.sol";

// handle the loans for a chama
contract Loans is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // We are going to use USDC by default
    EnumerableSet.AddressSet internal guarantors;
    IERC20 internal token;
    uint256 loanId;
    uint256 currentInterestRate;

    mapping(address member => uint256 amount) internal contrAmtFrozen;
    mapping(address member => mapping(address guarantor => uint256 amount)) internal loanAmtAvailable;
    mapping(address member => uint256 amount) internal memberToAmountContributed;
    mapping(uint256 loanId => Loan loan) internal loanIdToLoanDet;
    mapping(address member => uint256 loanId) internal memberToLoanId;

    uint256 internal constant BASIS_POINTS = 10000;
    bytes32 internal constant MEMBER_ROLE = keccak256("MEMBER_ROLE");
    bytes32 internal constant CHAMA_ADMIN_ROLE = keccak256("CHAMA_ADMIN_ROLE");

    struct Loan {
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;
        uint256 deadline;
    }

    event LoanTaken(
        address indexed member,
        uint256 amount,
        uint256 interestRate,
        uint256 startTime,
        uint256 deadline,
        uint256 indexed loanId
    );

    constructor(address _token, uint256 _interestRate) {
        if (_interestRate > BASIS_POINTS) revert Errors.Loans_invalidInterestRate(BASIS_POINTS, _interestRate);
        currentInterestRate = _interestRate;
        token = IERC20(_token);
        loanId = 0;
    }

    function guaranteeLoan(address _member, uint256 _amount) external onlyRole(MEMBER_ROLE) {
        if (memberToAmountContributed[_member] < _amount) {
            revert Errors.Loans__contrAmtLessLoanAmt(memberToAmountContributed[_member], _amount);
        }
        contrAmtFrozen[msg.sender] += _amount;
        loanAmtAvailable[_member][msg.sender] += _amount;
    }

    function takeLoan(uint256 _amount, uint256 _deadline, address guarantor)
        external
        onlyRole(MEMBER_ROLE)
        nonReentrant
    {
        if (_amount > loanAmtAvailable[msg.sender][guarantor]) {
            revert Errors.Loans__loanAmtGreaterThanGuaranteedAmt(_amount, loanAmtAvailable[msg.sender][guarantor]);
        }
        loanIdToLoanDet[loanId] =
            Loan({amount: _amount, interestRate: currentInterestRate, startTime: block.timestamp, deadline: _deadline});
        loanAmtAvailable[msg.sender][guarantor] -= _amount;
        token.safeTransfer(msg.sender, _amount);
        emit LoanTaken(msg.sender, _amount, currentInterestRate, block.timestamp, _deadline, loanId);
        loanId++;
    }

    function repayLoan(uint256 _amount, uint256 _loanId, address _guarantor)
        external
        onlyRole(MEMBER_ROLE)
        nonReentrant
    {
        Loan memory loan = loanIdToLoanDet[_loanId];
        // Calculate Interest Rate
        uint256 interestAccrued = (loan.amount * loan.interestRate) / BASIS_POINTS;
        uint256 totalRepayment = loan.amount + interestAccrued;
        if (_amount < totalRepayment) {
            loanIdToLoanDet[loanId].amount -= _amount;
        } else if (_amount == totalRepayment) {
            delete loanIdToLoanDet[loanId];
        } else {
            revert Errors.Loans__repayLoanAmountGreaterThanTotalRepayment(_amount, totalRepayment);
        }
        contrAmtFrozen[_guarantor] -= _amount;
        // add some more logic and checks here
        token.safeTransferFrom(msg.sender, address(this), _amount);
    }
}
