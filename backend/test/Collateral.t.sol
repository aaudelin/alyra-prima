// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Collateral} from "../src/Collateral.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PrimaToken} from "../src/PrimaToken.sol";

contract CollateralTest is Test {
    Collateral private collateral;
    PrimaToken private primaToken;
    address private owner = address(this);
    address private debtor = makeAddr("debtor");

    function setUp() public {
        primaToken = new PrimaToken();
        collateral = new Collateral(owner, address(primaToken));
    }

    function test_Deposit_Success() public {
        collateral.deposit(debtor, 100);
        assertEq(collateral.getCollateral(debtor), 100);
        assertEq(primaToken.allowance(address(collateral), owner), 100);
    }

    function test_Deposit_OnlyOwner() public {
        vm.prank(debtor);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor));
        collateral.deposit(debtor, 100);
    }

    function test_Deposit_ZeroAmount() public {
        collateral.deposit(debtor, 0);
        assertEq(collateral.getCollateral(debtor), 0);
    }

    function test_Deposit_MultipleDeposits() public {
        collateral.deposit(debtor, 100);
        collateral.deposit(debtor, 200);
        assertEq(collateral.getCollateral(debtor), 300);
    }

    function test_Withdraw_Success() public {
        collateral.deposit(debtor, 100);
        collateral.withdraw(debtor, 50);
        assertEq(collateral.getCollateral(debtor), 50);
    }

    function test_Withdraw_OnlyOwner() public {
        vm.prank(debtor);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor));
        collateral.withdraw(debtor, 50);
    }

    function test_Withdraw_NotEnoughCollateral() public {
        vm.expectRevert();
        collateral.withdraw(debtor, 150);
    }

    function test_Withdraw_ZeroAmount() public {
        collateral.deposit(debtor, 100);
        collateral.withdraw(debtor, 0);
        assertEq(collateral.getCollateral(debtor), 100);
    }

    function test_Withdraw_MultipleWithdrawals() public {
        collateral.deposit(debtor, 100);
        collateral.withdraw(debtor, 50);
        collateral.withdraw(debtor, 50);
        assertEq(collateral.getCollateral(debtor), 0);
    }

    function test_Withdraw_Failure_MultipleWithdrawals() public {
        collateral.deposit(debtor, 100);
        collateral.withdraw(debtor, 50);
        vm.expectRevert();
        collateral.withdraw(debtor, 100);
    }
}
