// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

library Errors {
    /*//////////////////////////////////////////////////////////////
                                 CHAMA
    //////////////////////////////////////////////////////////////*/
    error Chama__onlyFactoryAdminCanCall();
    error chama__zeroAddressProvided();
    error Chama__onlyChamaAdminCanCall();

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
    error Contributions__amountThatCanBeWithdrawnIs(uint256);
    error Contributions__notMemberInChama();
    error Contributions__memberShouldHaveZeroBalance(uint256);
    error Contributions__zeroAddressProvided();
}
