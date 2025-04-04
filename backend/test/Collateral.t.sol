// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Collateral} from "../src/Collateral.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PrimaToken} from "../src/PrimaToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CollateralTest is Test {
    Collateral private collateral;
    PrimaToken private primaToken;
    address private owner = address(this);
    address private debtor = makeAddr("debtor");
    address private investor = makeAddr("investor");

    function setUp() public {
        primaToken = new PrimaToken();
        collateral = new Collateral(owner, address(primaToken));
        primaToken.mint(debtor, 1000);
        primaToken.mint(address(collateral), 1000);
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
        uint256 collateralBalance = primaToken.balanceOf(address(collateral));
        collateral.deposit(debtor, 100);
        collateral.withdraw(debtor, investor, 50);
        assertEq(collateral.getCollateral(debtor), 50);
        assertEq(primaToken.balanceOf(investor), 50);
        assertEq(primaToken.balanceOf(address(collateral)), collateralBalance - 50);
    }

    function test_Withdraw_OnlyOwner() public {
        vm.prank(debtor);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor));
        collateral.withdraw(debtor, investor, 50);
    }

    function test_Withdraw_NotEnoughCollateral() public {
        vm.expectRevert();
        collateral.withdraw(debtor, investor, 150);
    }

    function test_Withdraw_ZeroAmount() public {
        uint256 collateralBalance = primaToken.balanceOf(address(collateral));
        collateral.deposit(debtor, 100);
        collateral.withdraw(debtor, investor, 0);
        assertEq(collateral.getCollateral(debtor), 100);
        assertEq(primaToken.balanceOf(investor), 0);
        assertEq(primaToken.balanceOf(address(collateral)), collateralBalance);
    }

    function test_Withdraw_MultipleWithdrawals() public {
        uint256 collateralBalance = primaToken.balanceOf(address(collateral));
        collateral.deposit(debtor, 100);
        collateral.withdraw(debtor, investor, 50);
        collateral.withdraw(debtor, investor, 50);
        assertEq(collateral.getCollateral(debtor), 0);
        assertEq(primaToken.balanceOf(investor), 100);
        assertEq(primaToken.balanceOf(address(collateral)), collateralBalance - 100);
    }

    function test_Withdraw_Failure_MultipleWithdrawals() public {
        collateral.deposit(debtor, 100);
        collateral.withdraw(debtor, investor, 50);
        vm.expectRevert();
        collateral.withdraw(debtor, investor, 100);
    }

    function test_Withdraw_Failure_TransferFailed() public {
        collateral.deposit(debtor, 100);
        vm.mockCall(address(primaToken), abi.encodeWithSelector(ERC20.transfer.selector), abi.encode(false));
        vm.expectRevert();
        collateral.withdraw(debtor, investor, 100);
    }

    function test_Deposit_Failure_ApproveFailed() public {
        vm.mockCall(address(primaToken), abi.encodeWithSelector(ERC20.approve.selector), abi.encode(false));
        vm.expectRevert();
        collateral.deposit(debtor, 100);
    }

    function test_GetCollateral() public {
        collateral.deposit(debtor, 100);
        assertEq(collateral.getCollateral(debtor), 100);
    }

    function test_InsufficientCollateral() public {
        vm.expectRevert(abi.encodeWithSelector(Collateral.Collateral_InsufficientCollateral.selector, debtor, 100, 0));
        collateral.withdraw(debtor, investor, 100);
    }
}
