// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract InvoiceNFTCreateInvoiceTest is Test {
    InvoiceNFT private invoiceNFT;
    address private debtor = makeAddr("debtor");
    address private creditor = makeAddr("creditor");
    address private owner = address(this);
    InvoiceNFT.Company private creditorCompany;
    InvoiceNFT.Company private debtorCompany;
    InvoiceNFT.InvoiceParams private invoice;

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
        debtorCompany = InvoiceNFT.Company(debtor, InvoiceNFT.CreditScore.B);
        creditorCompany = InvoiceNFT.Company(creditor, InvoiceNFT.CreditScore.A);
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890", "Activity", "USA", block.timestamp, 1000, 900, debtorCompany, creditorCompany
        );
    }

    function test_CreateInvoice_Success() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        assertEq(tokenId, 1);
        assertEq(invoiceNFT.balanceOf(creditor), 1);
        assertEq(invoiceNFT.getInvoice(tokenId).id, invoice.id);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.NEW));
        assertEq(invoiceNFT.getInvoice(tokenId).collateral, 0);
        assertEq(invoiceNFT.getInvoice(tokenId).investor.name, address(0));
    }

    function test_CreateInvoice_Success_Emit() public {
        vm.expectEmit();
        emit IERC721.Transfer(address(0), creditor, 1);
        vm.expectEmit();
        emit InvoiceNFT.InvoiceNFT_StatusChanged(1, InvoiceNFT.InvoiceStatus.NEW);
        invoiceNFT.createInvoice(creditor, invoice);
    }

    function test_CreateInvoice_Revert_NotOwner() public {
        vm.prank(debtor);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor));
        invoiceNFT.createInvoice(creditor, invoice);
    }

    function test_CreateInvoice_MutipleInvoices() public {
        InvoiceNFT.InvoiceParams memory invoice2 = InvoiceNFT.InvoiceParams(
            "1111111111", "Military", "France", block.timestamp, 3000, 900, debtorCompany, creditorCompany
        );

        uint256 tokenId1 = invoiceNFT.createInvoice(creditor, invoice);
        uint256 tokenId2 = invoiceNFT.createInvoice(creditor, invoice2);
        assertEq(invoiceNFT.ownerOf(tokenId1), creditor);
        assertEq(invoiceNFT.ownerOf(tokenId2), creditor);
        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
    }

    function test_CreateInvoice_CreateSameInvoiceTwice() public {
        uint256 tokenId1 = invoiceNFT.createInvoice(creditor, invoice);
        uint256 tokenId2 = invoiceNFT.createInvoice(debtor, invoice);
        assertEq(invoiceNFT.ownerOf(tokenId1), creditor);
        assertEq(invoiceNFT.ownerOf(tokenId2), debtor);
        assertEq(tokenId1, 1);
        assertEq(tokenId2, 2);
    }

    function test_CreateInvoice_Revert_ZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        invoiceNFT.createInvoice(address(0), invoice);
    }
}

contract InvoiceNFTGetInvoiceTest is Test {
    InvoiceNFT private invoiceNFT;
    address private debtor = makeAddr("debtor");
    address private creditor = makeAddr("creditor");
    address private owner = address(this);
    InvoiceNFT.Company private creditorCompany;
    InvoiceNFT.Company private debtorCompany;
    InvoiceNFT.InvoiceParams private invoice;

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
        debtorCompany = InvoiceNFT.Company(debtor, InvoiceNFT.CreditScore.B);
        creditorCompany = InvoiceNFT.Company(creditor, InvoiceNFT.CreditScore.A);
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890", "Activity", "USA", block.timestamp, 1000, 900, debtorCompany, creditorCompany
        );
    }

    function test_GetInvoice_Success() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        InvoiceNFT.Invoice memory retrievedInvoice = invoiceNFT.getInvoice(tokenId);
        assertEq(retrievedInvoice.id, invoice.id);
    }

    function test_GetInvoice_Revert_NotOwner() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.prank(debtor);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor));
        invoiceNFT.getInvoice(tokenId);
    }

    function testFuzz_GetInvoice_Revert_NotMinted(uint256 tokenId) public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, tokenId));
        invoiceNFT.getInvoice(tokenId);
    }

    function testFuzz_GetInvoice_Revert_OneMinted(uint256 tokenId) public {
        invoiceNFT.createInvoice(creditor, invoice);
        if (tokenId != 1) {
            vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, tokenId));
            invoiceNFT.getInvoice(tokenId);
        }
    }
}

contract InvoiceNFTAcceptInvoiceTest is Test {
    InvoiceNFT private invoiceNFT;
    address private debtor = makeAddr("debtor");
    address private creditor = makeAddr("creditor");
    address private owner = address(this);
    InvoiceNFT.Company private creditorCompany;
    InvoiceNFT.Company private debtorCompany;
    InvoiceNFT.InvoiceParams private invoice;

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
        debtorCompany = InvoiceNFT.Company(debtor, InvoiceNFT.CreditScore.B);
        creditorCompany = InvoiceNFT.Company(creditor, InvoiceNFT.CreditScore.A);
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890", "Activity", "USA", block.timestamp, 1000, 900, debtorCompany, creditorCompany
        );
    }

    function test_AcceptInvoice_SuccessNoCollateral() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.expectEmit();
        emit InvoiceNFT.InvoiceNFT_StatusChanged(tokenId, InvoiceNFT.InvoiceStatus.ACCEPTED);
        invoiceNFT.acceptInvoice(tokenId, 0);
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.ACCEPTED));
        assertEq(invoiceNFT.getInvoice(tokenId).collateral, 0);
    }

    function test_AcceptInvoice_SuccessWithCollateral() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.expectEmit();
        emit InvoiceNFT.InvoiceNFT_StatusChanged(tokenId, InvoiceNFT.InvoiceStatus.ACCEPTED);
        invoiceNFT.acceptInvoice(tokenId, 100);
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.ACCEPTED));
        assertEq(invoiceNFT.getInvoice(tokenId).collateral, 100);
    }

    function test_AcceptInvoice_Revert_NotOwner() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.prank(debtor);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor));
        invoiceNFT.acceptInvoice(tokenId, 0);
    }

    function test_AcceptInvoice_Revert_NotMinted() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 1));
        invoiceNFT.acceptInvoice(1, 0);
    }

    function test_AcceptInvoice_Revert_WrongStatus() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                InvoiceNFT.InvoiceNFT_WrongInvoiceStatus.selector, tokenId, uint256(InvoiceNFT.InvoiceStatus.ACCEPTED)
            )
        );
        invoiceNFT.acceptInvoice(tokenId, 0);
    }
}

contract InvoiceNFTInvestInvoiceTest is Test {
    InvoiceNFT private invoiceNFT;
    address private investor = makeAddr("investor");
    address private debtor = makeAddr("debtor");
    address private creditor = makeAddr("creditor");
    address private owner = address(this);
    InvoiceNFT.Company private investorCompany;
    InvoiceNFT.Company private creditorCompany;
    InvoiceNFT.Company private debtorCompany;
    InvoiceNFT.InvoiceParams private invoice;

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
        debtorCompany = InvoiceNFT.Company(debtor, InvoiceNFT.CreditScore.B);
        creditorCompany = InvoiceNFT.Company(creditor, InvoiceNFT.CreditScore.A);
        investorCompany = InvoiceNFT.Company(investor, InvoiceNFT.CreditScore.A);
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890", "Activity", "USA", block.timestamp, 1000, 300, debtorCompany, creditorCompany
        );
    }

    function test_InvestInvoice_Success() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        invoiceNFT.acceptInvoice(tokenId, 0);
        vm.expectEmit();
        emit IERC721.Transfer(creditor, investor, tokenId);
        vm.expectEmit();
        emit InvoiceNFT.InvoiceNFT_StatusChanged(tokenId, InvoiceNFT.InvoiceStatus.IN_PROGRESS);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        assertEq(invoiceNFT.ownerOf(tokenId), investor);
        assertEq(invoiceNFT.getInvoice(tokenId).investor.name, investor);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.IN_PROGRESS));
    }

    function test_InvestInvoice_Revert_NotOwner() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        vm.prank(debtor);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor));
        invoiceNFT.investInvoice(tokenId, investorCompany);
    }

    function test_InvestInvoice_Revert_NotMinted() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 1));
        invoiceNFT.investInvoice(1, investorCompany);
    }

    function test_InvestInvoice_ZeroAddress() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        invoiceNFT.investInvoice(tokenId, InvoiceNFT.Company(address(0), InvoiceNFT.CreditScore.A));
    }

    function test_InvestInvoice_Revert_WrongStatus() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.expectRevert(
            abi.encodeWithSelector(
                InvoiceNFT.InvoiceNFT_WrongInvoiceStatus.selector, tokenId, uint256(InvoiceNFT.InvoiceStatus.NEW)
            )
        );
        invoiceNFT.investInvoice(tokenId, investorCompany);
    }
}

contract InvoiceNFTPayInvoiceTest is Test {
    InvoiceNFT private invoiceNFT;
    address private investor = makeAddr("investor");
    address private debtor = makeAddr("debtor");
    address private creditor = makeAddr("creditor");
    address private owner = address(this);
    InvoiceNFT.Company private investorCompany;
    InvoiceNFT.Company private creditorCompany;
    InvoiceNFT.Company private debtorCompany;
    InvoiceNFT.InvoiceParams private invoice;

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
        debtorCompany = InvoiceNFT.Company(debtor, InvoiceNFT.CreditScore.B);
        creditorCompany = InvoiceNFT.Company(creditor, InvoiceNFT.CreditScore.A);
        investorCompany = InvoiceNFT.Company(investor, InvoiceNFT.CreditScore.A);
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890", "Activity", "USA", block.timestamp, 1000, 300, debtorCompany, creditorCompany
        );
    }

    function test_PayInvoice_Success_PaymentSuccess() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        vm.expectEmit();
        emit InvoiceNFT.InvoiceNFT_StatusChanged(tokenId, InvoiceNFT.InvoiceStatus.PAID);
        invoiceNFT.payInvoice(tokenId, true);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.PAID));
    }

    function test_PayInvoice_Success_PaymentSuccessOverdue() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        invoiceNFT.payInvoice(tokenId, false);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.OVERDUE));
        vm.expectEmit();
        emit InvoiceNFT.InvoiceNFT_StatusChanged(tokenId, InvoiceNFT.InvoiceStatus.PAID);
        invoiceNFT.payInvoice(tokenId, true);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.PAID));
    }

    function test_PayInvoice_Success_PaymentFailed() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        vm.expectEmit();
        emit InvoiceNFT.InvoiceNFT_StatusChanged(tokenId, InvoiceNFT.InvoiceStatus.OVERDUE);
        invoiceNFT.payInvoice(tokenId, false);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.OVERDUE));
    }

    function test_PayInvoice_Revert_NotOwner() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        vm.prank(debtor);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor));
        invoiceNFT.payInvoice(tokenId, true);
    }

    function test_PayInvoice_Revert_NotMinted() public {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 1));
        invoiceNFT.payInvoice(1, true);
    }

    function test_PayInvoice_Revert_WrongStatus() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                InvoiceNFT.InvoiceNFT_WrongInvoiceStatus.selector, tokenId, uint256(InvoiceNFT.InvoiceStatus.ACCEPTED)
            )
        );
        invoiceNFT.payInvoice(tokenId, true);
    }
}

contract InvoiceNFTTokenURI is Test {
    InvoiceNFT private invoiceNFT;
    address private owner = address(this);
    address private creditor = makeAddr("creditor");
    address private debtor = makeAddr("debtor");
    InvoiceNFT.Company private creditorCompany;
    InvoiceNFT.Company private debtorCompany;
    InvoiceNFT.InvoiceParams private invoice;

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
        debtorCompany = InvoiceNFT.Company(debtor, InvoiceNFT.CreditScore.B);
        creditorCompany = InvoiceNFT.Company(creditor, InvoiceNFT.CreditScore.A);
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890", "Activity", "USA", block.timestamp, 1000, 300, debtorCompany, creditorCompany
        );
    }

    function test_TokenURI() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        console.log(invoiceNFT.tokenURI(tokenId));
        assertEq(
            invoiceNFT.tokenURI(tokenId),
            "data:application/json;base64,eyJuYW1lIjoiUHJpbWEgSW52b2ljZXMiLCAiZGVzY3JpcHRpb24iOiJJbnZvaWNlcyBnZW5lcmF0ZWQgYnkgUHJpbWEiLCAiYXR0cmlidXRlcyI6IFt7ImlkIjoiMTIzNDU2Nzg5MCIsICJhY3Rpdml0eSI6IkFjdGl2aXR5IiwgImNvdW50cnkiOiJVU0EiLCAiZHVlRGF0ZSI6IjEiLCAiYW1vdW50IjoiMTAwMCIsICJhbW91bnRUb1BheSI6IjMwMCJ9XSwgImltYWdlIjoiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpT0RBd0lpQm9aV2xuYUhROUlqWXdNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajRLSUNBOElTMHRJRUpoWTJ0bmNtOTFibVFnTFMwK0NpQWdQR1JsWm5NK0NpQWdJQ0E4YkdsdVpXRnlSM0poWkdsbGJuUWdhV1E5SW1KblIzSmhaR2xsYm5RaUlIZ3hQU0l3SWlCNU1UMGlNQ0lnZURJOUlqQWlJSGt5UFNJeElqNEtJQ0FnSUNBZ1BITjBiM0FnYjJabWMyVjBQU0l3SlNJZ2MzUnZjQzFqYjJ4dmNqMGlJMlUyWlRGbU5TSXZQZ29nSUNBZ0lDQThjM1J2Y0NCdlptWnpaWFE5SWpFd01DVWlJSE4wYjNBdFkyOXNiM0k5SWlOak9XSmtaVFVpTHo0S0lDQWdJRHd2YkdsdVpXRnlSM0poWkdsbGJuUStDaUFnUEM5a1pXWnpQZ29nSUR4eVpXTjBJSGRwWkhSb1BTSXhNREFsSWlCb1pXbG5hSFE5SWpFd01DVWlJR1pwYkd3OUluVnliQ2dqWW1kSGNtRmthV1Z1ZENraUx6NEtDaUFnUENFdExTQlVhWFJzWlNBdExUNEtJQ0E4ZEdWNGRDQjRQU0kxTUNVaUlIazlJakV3TUNJZ2RHVjRkQzFoYm1Ob2IzSTlJbTFwWkdSc1pTSWdabTl1ZEMxemFYcGxQU0kyTkNJZ1ptOXVkQzFtWVcxcGJIazlJbk5sY21sbUlpQm1hV3hzUFNJak1XRXhZVEZoSWlCemRIbHNaVDBpWm05dWRDMXpkSGxzWlRvZ2FYUmhiR2xqT3lCc1pYUjBaWEl0YzNCaFkybHVaem9nTW5CNE95SStDaUFnSUNCUWNtbHRZUW9nSUR3dmRHVjRkRDRLQ2lBZ1BDRXRMU0JKYm5admFXTmxJRXhoWW1Wc0lDMHRQZ29nSUR4MFpYaDBJSGc5SWpVd0pTSWdlVDBpTVRZd0lpQjBaWGgwTFdGdVkyaHZjajBpYldsa1pHeGxJaUJtYjI1MExYTnBlbVU5SWpJMElpQm1iMjUwTFdaaGJXbHNlVDBpUjJWdmNtZHBZU0lnWm1sc2JEMGlJMkUyTjJNd01DSWdiR1YwZEdWeUxYTndZV05wYm1jOUlqTWlQZ29nSUNBZ1NVNVdUMGxEUlFvZ0lEd3ZkR1Y0ZEQ0S0NpQWdQQ0V0TFNCSmJuWnZhV05sSUVKdlpIa2dMUzArQ2lBZ1BISmxZM1FnZUQwaU1UQXdJaUI1UFNJeU1EQWlJSGRwWkhSb1BTSTJNREFpSUdobGFXZG9kRDBpTXpBd0lpQnllRDBpTWpBaUlISjVQU0l5TUNJZ1ptbHNiRDBpSTJabVptWm1aaUlnYzNSeWIydGxQU0lqWkRSak1tWXdJaUJ6ZEhKdmEyVXRkMmxrZEdnOUlqSWlMejRLSUNBS0lDQThJUzB0SUZSaFlteGxJRWhsWVdScGJtZHpJQzB0UGdvS0lDQThJUzB0SUVScGRtbGtaWElnVEdsdVpTQXRMVDRLSUNBOGJHbHVaU0I0TVQwaU1USXdJaUI1TVQwaU1qUTFJaUI0TWowaU5qZ3dJaUI1TWowaU1qUTFJaUJ6ZEhKdmEyVTlJaU5qWTJNaUlITjBjbTlyWlMxM2FXUjBhRDBpTVNJdlBnb0tJQ0E4SVMwdElFWnZiM1JsY2lCdGIyNXZaM0poYlNBdExUNEtJQ0E4ZEdWNGRDQjRQU0kzTWpBaUlIazlJalUxTUNJZ1ptOXVkQzF6YVhwbFBTSXlNQ0lnWm1sc2JEMGlJems1T1NJZ1ptOXVkQzFtWVcxcGJIazlJa2RsYjNKbmFXRWlJRzl3WVdOcGRIazlJakF1TnlJK0NpQWdJQ0JhQ2lBZ1BDOTBaWGgwUGdvOEwzTjJaejQ9In0="
        );
    }
}
