// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title PrimaToken
 * @notice ERC20 token for the Prima project
 * @dev This is a simple ERC20 token implementation for the Prima project.
 * @dev This token is used only for testing purposes.
 */
contract PrimaToken is ERC20 {
    constructor() ERC20("Prima", "PGT") {}

    /**
     * @notice Mint the amount of tokens to the address
     * @param to: The address to mint the token to
     * @param amount: The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
