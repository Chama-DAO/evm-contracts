// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

library Errors {
    /*//////////////////////////////////////////////////////////////
                                 LOANS
    //////////////////////////////////////////////////////////////*/
    error Loans_invalidInterestRate(uint256 maxInterestRate, uint256 currentInterestRate);
    error Loans__contrAmtLessLoanAmt(uint256 contrAmt, uint256 loanAmt);
    error Loans__loanAmtGreaterThanGuaranteedAmt(uint256 loanAmt, uint256 guaranteedAmt);
    error Loans__repayLoanAmountGreaterThanTotalRepayment(uint256 repaymentAmount, uint256 totalRepaymentAmount);

    /*//////////////////////////////////////////////////////////////
                                 CHAMA
    //////////////////////////////////////////////////////////////*/
    error Chama__onlyFactoryAdminCanCall();
    error chama__zeroAddressProvided();
    error Chama__onlyChamaAdminCanCall();
    error Chama__defaultTokenNotSet();

    /*//////////////////////////////////////////////////////////////
                          OPENZEPPELIN OWNABLE
    //////////////////////////////////////////////////////////////*/
    error Ownable__OwnableUnauthorizedAccount(address);

    /*//////////////////////////////////////////////////////////////
                             CONTRIBUTIONS
    //////////////////////////////////////////////////////////////*/
    error Contributions__onlyMembersCanCall(address);
    error Contributions__memberAlreadyInChama(address);
    error Contributions__zeroAmountProvided();
    error Contributions__tokenBalanceMustBeZero();
    error Contributions__amountNotAvailable(uint256);
    error Contributions__notMemberInChama();
    error Contributions__memberShouldHaveZeroBalance(uint256);
    error Contributions__zeroAddressProvided();
    error Contributions__notFactoryContract();
    error Contributions__epochNotOver();

    /*//////////////////////////////////////////////////////////////
                        STABLECOIN POOL FACTORY
    //////////////////////////////////////////////////////////////*/

    error PoolFactory__PoolAlreadyExists(address pool);
    error PoolFactory__ArrayLengthMismatch();
}
