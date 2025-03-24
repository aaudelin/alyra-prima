// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";

contract InvoiceNFTScript is Script {
    InvoiceNFT public invoiceNFT;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        invoiceNFT = new InvoiceNFT(msg.sender);

        vm.stopBroadcast();
    }
}
