// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PrimaToken} from "../src/PrimaToken.sol";

/**
 * @title PrimaTokenScript
 * @notice Script for deploying the PrimaToken contract
 * @author @aaudelin
 */
contract PrimaTokenScript is Script {
    PrimaToken public primaToken;

    function run() public {
        vm.startBroadcast(msg.sender);

        primaToken = new PrimaToken();
        console.log("PrimaToken deployed at", address(primaToken));

        vm.stopBroadcast();
    }
}
