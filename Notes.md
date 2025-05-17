## Notes

- changeContributiontoken seems to have a evm revert error, remember to check on it -This was done
- When removing members from chama, their roles are not revoked
- Update deadline to be greater than the current block timestamp
- There is an arithmetic overflow/underflow in repay function, check on it -params used = amount = 1e6
