// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Prima} from "../src/Prima.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {Collateral} from "../src/Collateral.sol";

contract PrimaScript is Script {
    Prima public prima;

    function run(address primaTokenAddress) public {
        vm.startBroadcast(msg.sender);
        
        InvoiceNFT invoiceNFT = new InvoiceNFT(msg.sender);
        Collateral collateral = new Collateral(msg.sender);
        console.log("InvoiceNFT deployed at", address(invoiceNFT));
        console.log("Collateral deployed at", address(collateral));

        prima = new Prima(address(invoiceNFT), address(collateral), primaTokenAddress);
        console.log("Prima deployed at", address(prima));

        invoiceNFT.transferOwnership(address(prima));
        collateral.transferOwnership(address(prima));

        vm.stopBroadcast();
    }
}
