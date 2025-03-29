// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PrimaToken} from "./PrimaToken.sol";

/**
 * @title Collateral
 * @notice Collateral contract for the Prima project, this account is responsible for managing the collateral of Debtors
 * @dev This contract receives some ERC20 and updates the balances
 * @dev This contract is owned by the Prima contract
 * @author @aaudelin
 */
contract Collateral is Ownable {
    /**
     * @notice Mapping of the collateral balances of the Debtors
     */
    mapping(address => uint256) private collateral;

    /**
     * @notice PrimaToken contract
     */
    PrimaToken public primaToken;

    /**
     * @notice Constructor
     * @param owner: The owner of the contract
     */
    constructor(address owner, address primaTokenAddress) Ownable(owner) {
        primaToken = PrimaToken(primaTokenAddress);
    }

    error Collateral_InsufficientCollateral(address debtor, uint256 collateralAmount, uint256 availableCollateral);

    /**
     * @notice Deposit the collateral amount to the address
     * @dev This function also allows the owner to spend the collateral amount
     * @param to: The address to deposit the collateral to
     * @param collateralAmount: The amount of collateral to deposit
     */
    function deposit(address to, uint256 collateralAmount) external onlyOwner {
        collateral[to] += collateralAmount;
        primaToken.approve(owner(), collateral[to]);
    }

    /**
     * @notice Withdraw the collateral amount from the address
     * @param from: The address to withdraw the collateral from
     * @param collateralAmount: The amount of collateral to withdraw
     */
    function withdraw(address from, uint256 collateralAmount) external onlyOwner {
        require(
            collateral[from] >= collateralAmount,
            Collateral_InsufficientCollateral(from, collateralAmount, collateral[from])
        );
        collateral[from] -= collateralAmount;
    }

    /**
     * @notice Get the collateral amount of the address
     * @param account: The address to get the collateral amount from
     * @return collateralAmount: The amount of collateral
     */
    function getCollateral(address account) external view onlyOwner returns (uint256) {
        return collateral[account];
    }
}
