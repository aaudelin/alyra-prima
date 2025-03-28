// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Prima} from "../src/Prima.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {Collateral} from "../src/Collateral.sol";

contract PrimaScript is Script {
    Prima public prima;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        InvoiceNFT invoiceNFT = new InvoiceNFT(msg.sender);
        Collateral collateral = new Collateral(msg.sender);

        prima = new Prima(address(invoiceNFT), address(collateral));
        console.log("Prima deployed at", address(prima));
        console.log("InvoiceNFT deployed at", address(invoiceNFT));
        console.log("Collateral deployed at", address(collateral));

        console.log("InvoiceNFT owner", invoiceNFT.owner(), msg.sender);
        require(invoiceNFT.owner() == msg.sender, "InvoiceNFT owner is not the sender");
        console.log("Collateral owner", collateral.owner(), msg.sender);
        require(collateral.owner() == msg.sender, "Collateral owner is not the sender");

        invoiceNFT.transferOwnership(address(prima));
        collateral.transferOwnership(address(prima));

        vm.stopBroadcast();
    }
}
