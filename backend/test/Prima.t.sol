// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {Prima} from "../src/Prima.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";

contract PrimaCollateralTest is Test {
    Prima prima;
    InvoiceNFT invoiceNFT;

    address debtor = makeAddr("debtor");
    address creditor = makeAddr("creditor");
    address investor = makeAddr("investor");

    address private owner = address(this);

    function setUp() public {
        // Deploy contracts
        invoiceNFT = new InvoiceNFT(owner);
        prima = new Prima();

        // Setup test accounts
        vm.deal(debtor, 100 ether);
        vm.deal(creditor, 100 ether);
        vm.deal(investor, 100 ether);
    }
}
