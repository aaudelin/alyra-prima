// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {Prima} from "../src/Prima.sol";
import "../script/Prima.s.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {Collateral} from "../src/Collateral.sol";

contract PrimaDeploymentTest is Test {
    Prima prima;
    PrimaScript primaScript;
    address debtor = makeAddr("debtor");
    address creditor = makeAddr("creditor");
    address investor = makeAddr("investor");

    address private owner = address(this);

    function setUp() public {
        primaScript = new PrimaScript();
        primaScript.run();
        prima = primaScript.prima();
    }

    function test_Deployment_Prima() public {
        assertNotEq(address(prima), address(0));
    }

    function test_Deployment_ChildrenContracts() public view {
        assertNotEq(address(prima.invoiceNFT()), address(0));
        assertNotEq(address(prima.collateral()), address(0));

        assertEq(prima.invoiceNFT().owner(), address(prima));
        assertEq(prima.collateral().owner(), address(prima));
    }
}

contract PrimaCollateralTest is Test {
    Prima prima;
    Collateral collateral;

    address debtor = makeAddr("debtor");
    address creditor = makeAddr("creditor");
    address investor = makeAddr("investor");

    address private owner = address(this);

    function setUp() public {
        // Deploy contracts
        PrimaScript primaScript = new PrimaScript();
        primaScript.run();
        prima = primaScript.prima();
        collateral = prima.collateral();

        // Setup test accounts
        vm.deal(debtor, 100 ether);
        vm.deal(creditor, 100 ether);
        vm.deal(investor, 100 ether);
    }
}
