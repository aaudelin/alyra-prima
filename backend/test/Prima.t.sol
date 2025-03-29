// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {Prima} from "../src/Prima.sol";
import "../script/Prima.s.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {Collateral} from "../src/Collateral.sol";
import {PrimaToken} from "../src/PrimaToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract PrimaDeploymentTest is Test {
    Prima prima;
    PrimaScript primaScript;
    address debtor = makeAddr("debtor");
    address creditor = makeAddr("creditor");
    address investor = makeAddr("investor");

    address private owner = address(this);

    function test_Deployment_Script() public {
        PrimaToken primaToken = new PrimaToken();
        primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();

        assertNotEq(address(prima), address(0));
        assertNotEq(address(prima.invoiceNFT()), address(0));
        assertNotEq(address(prima.collateral()), address(0));
        assertNotEq(address(prima.primaToken()), address(0));
        assertEq(prima.invoiceNFT().owner(), address(prima));
        assertEq(prima.collateral().owner(), address(prima));
    }
}

contract PrimaCollateralTest is Test {
    Prima prima;
    Collateral collateral;
    PrimaToken primaToken;
    uint256 primaTokenDecimals;

    address debtor = makeAddr("debtor");

    function setUp() public {
        // Deploy contracts
        primaToken = new PrimaToken();
        PrimaScript primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();
        collateral = prima.collateral();
        primaTokenDecimals = primaToken.decimals();
    }

    function test_AddCollateral_Success() public {
        primaToken.mint(debtor, 1000000 * 10 ** primaTokenDecimals);
        uint256 collateralAmount = 100 * 10 ** primaTokenDecimals;
        vm.startPrank(debtor);
        primaToken.approve(address(prima), collateralAmount);
        prima.addCollateral(collateralAmount);
        vm.stopPrank();

        vm.startPrank(address(prima));
        assertEq(primaToken.balanceOf(address(collateral)), collateralAmount);
        assertEq(collateral.getCollateral(debtor), collateralAmount);
        assertEq(primaToken.allowance(address(collateral), address(prima)), collateralAmount);
        vm.stopPrank();
    }

    function test_AddCollateral_SuccessTwoDeposits() public {
        primaToken.mint(debtor, 1000000 * 10 ** primaTokenDecimals);
        uint256 collateralAmount = 100 * 10 ** primaTokenDecimals;
        vm.startPrank(debtor);
        primaToken.approve(address(prima), collateralAmount);
        prima.addCollateral(collateralAmount);
        primaToken.approve(address(prima), collateralAmount);
        prima.addCollateral(collateralAmount);
        vm.stopPrank();

        vm.startPrank(address(prima));
        assertEq(primaToken.balanceOf(address(collateral)), 2 * collateralAmount);
        assertEq(collateral.getCollateral(debtor), 2 * collateralAmount);
        assertEq(primaToken.allowance(address(collateral), address(prima)), 2 * collateralAmount);
        vm.stopPrank();
    }

    function test_AddCollateral_ZeroAllowance() public {
        vm.startPrank(debtor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector, address(prima), 0, 100 * 10 ** primaTokenDecimals
            )
        );
        prima.addCollateral(100 * 10 ** primaTokenDecimals);
        vm.stopPrank();
    }

    function test_AddCollateral_InsufficientAllowance() public {
        vm.startPrank(debtor);
        primaToken.approve(address(prima), 10 * 10 ** primaTokenDecimals);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                address(prima),
                10 * 10 ** primaTokenDecimals,
                100 * 10 ** primaTokenDecimals
            )
        );
        prima.addCollateral(100 * 10 ** primaTokenDecimals);
        vm.stopPrank();
    }
}

contract PrimaAmountsTest is Test {
    Prima prima;

    function setUp() public {
        // Deploy contracts
        PrimaToken primaToken = new PrimaToken();
        PrimaScript primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();
    }

    function test_ComputeAmounts_A() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.A);
        assertEq(minimumAmount, 95);
        assertEq(maximumAmount, 100);
    }

    function test_ComputeAmounts_B() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.B);
        assertEq(minimumAmount, 90);
        assertEq(maximumAmount, 95);
    }

    function test_ComputeAmounts_C() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.C);
        assertEq(minimumAmount, 85);
        assertEq(maximumAmount, 90);
    }

    function test_ComputeAmounts_D() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.D);
        assertEq(minimumAmount, 80);
        assertEq(maximumAmount, 85);
    }

    function test_ComputeAmounts_E() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.E);
        assertEq(minimumAmount, 75);
        assertEq(maximumAmount, 80);
    }

    function test_ComputeAmounts_F() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.F);
        assertEq(minimumAmount, 70);
        assertEq(maximumAmount, 75);
    }

    function test_ComputeAmounts_Zero() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(0, InvoiceNFT.CreditScore.A);
        assertEq(minimumAmount, 0);
        assertEq(maximumAmount, 0);
    }
}
