// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Collateral is Ownable {
    mapping(address => uint256) private collateral;

    constructor(address owner) Ownable(owner) {}

    function deposit(address to, uint256 collateralAmount) external onlyOwner {
        collateral[to] += collateralAmount;
    }

    function withdraw(address from, uint256 collateralAmount) external onlyOwner {
        collateral[from] -= collateralAmount;
    }

    function getCollateral(address account) external view onlyOwner returns (uint256) {
        return collateral[account];
    }
}
