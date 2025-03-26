// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PrimaToken is ERC20 {
    constructor() ERC20("Prima", "PGT") {}
}
