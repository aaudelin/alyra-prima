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
            "data:application/json;base64,eyJuYW1lIjoiUHJpbWEgSW52b2ljZSAxMjM0NTY3ODkwIiwgImRlc2NyaXB0aW9uIjoiSW52b2ljZXMgZ2VuZXJhdGVkIGJ5IFByaW1hIiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjoiSWQiLCJ2YWx1ZSI6IjEyMzQ1Njc4OTAifSwgeyJ0cmFpdF90eXBlIjoiQWN0aXZpdHkiLCJ2YWx1ZSI6IkFjdGl2aXR5In0sIHsidHJhaXRfdHlwZSI6IkNvdW50cnkiLCJ2YWx1ZSI6IlVTQSJ9LCB7InRyYWl0X3R5cGUiOiJEdWUgRGF0ZSIsInZhbHVlIjoiMSJ9LCB7InRyYWl0X3R5cGUiOiJBbW91bnQiLCJ2YWx1ZSI6IjEwMDAifSwgeyJ0cmFpdF90eXBlIjoiQW1vdW50IFRvIFBheSIsInZhbHVlIjoiMzAwIn1dLCAiaW1hZ2UiOiJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlPREF3SWlCb1pXbG5hSFE5SWpZd01DSWdlRzFzYm5NOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6SXdNREF2YzNabklqNEtJQ0E4SVMwdElFSmhZMnRuY205MWJtUWdMUzArQ2lBZ1BHUmxabk0rQ2lBZ0lDQThiR2x1WldGeVIzSmhaR2xsYm5RZ2FXUTlJbUpuUjNKaFpHbGxiblFpSUhneFBTSXdJaUI1TVQwaU1DSWdlREk5SWpBaUlIa3lQU0l4SWo0S0lDQWdJQ0FnUEhOMGIzQWdiMlptYzJWMFBTSXdKU0lnYzNSdmNDMWpiMnh2Y2owaUkyVTJaVEZtTlNJdlBnb2dJQ0FnSUNBOGMzUnZjQ0J2Wm1aelpYUTlJakV3TUNVaUlITjBiM0F0WTI5c2IzSTlJaU5qT1dKa1pUVWlMejRLSUNBZ0lEd3ZiR2x1WldGeVIzSmhaR2xsYm5RK0NpQWdQQzlrWldaelBnb2dJRHh5WldOMElIZHBaSFJvUFNJeE1EQWxJaUJvWldsbmFIUTlJakV3TUNVaUlHWnBiR3c5SW5WeWJDZ2pZbWRIY21Ga2FXVnVkQ2tpTHo0S0NpQWdQQ0V0TFNCVWFYUnNaU0F0TFQ0S0lDQThkR1Y0ZENCNFBTSTFNQ1VpSUhrOUlqRXdNQ0lnZEdWNGRDMWhibU5vYjNJOUltMXBaR1JzWlNJZ1ptOXVkQzF6YVhwbFBTSTJOQ0lnWm05dWRDMW1ZVzFwYkhrOUluTmxjbWxtSWlCbWFXeHNQU0lqTVdFeFlURmhJaUJ6ZEhsc1pUMGlabTl1ZEMxemRIbHNaVG9nYVhSaGJHbGpPeUJzWlhSMFpYSXRjM0JoWTJsdVp6b2dNbkI0T3lJK0NpQWdJQ0JRY21sdFlRb2dJRHd2ZEdWNGRENEtDaUFnUENFdExTQkpiblp2YVdObElFeGhZbVZzSUMwdFBnb2dJRHgwWlhoMElIZzlJalV3SlNJZ2VUMGlNVFl3SWlCMFpYaDBMV0Z1WTJodmNqMGliV2xrWkd4bElpQm1iMjUwTFhOcGVtVTlJakkwSWlCbWIyNTBMV1poYldsc2VUMGlSMlZ2Y21kcFlTSWdabWxzYkQwaUkyRTJOMk13TUNJZ2JHVjBkR1Z5TFhOd1lXTnBibWM5SWpNaVBnb2dJQ0FnU1U1V1QwbERSUW9nSUR3dmRHVjRkRDRLQ2lBZ1BDRXRMU0JKYm5admFXTmxJRUp2WkhrZ0xTMCtDaUFnUEhKbFkzUWdlRDBpTVRBd0lpQjVQU0l5TURBaUlIZHBaSFJvUFNJMk1EQWlJR2hsYVdkb2REMGlNekF3SWlCeWVEMGlNakFpSUhKNVBTSXlNQ0lnWm1sc2JEMGlJMlptWm1abVppSWdjM1J5YjJ0bFBTSWpaRFJqTW1Zd0lpQnpkSEp2YTJVdGQybGtkR2c5SWpJaUx6NEtJQ0FLSUNBOElTMHRJRlJoWW14bElFaGxZV1JwYm1keklDMHRQZ29LSUNBOElTMHRJRVJwZG1sa1pYSWdUR2x1WlNBdExUNEtJQ0E4YkdsdVpTQjRNVDBpTVRJd0lpQjVNVDBpTWpRMUlpQjRNajBpTmpnd0lpQjVNajBpTWpRMUlpQnpkSEp2YTJVOUlpTmpZMk1pSUhOMGNtOXJaUzEzYVdSMGFEMGlNU0l2UGdvS0lDQThJUzB0SUVadmIzUmxjaUJ0YjI1dlozSmhiU0F0TFQ0S0lDQThkR1Y0ZENCNFBTSTNNakFpSUhrOUlqVTFNQ0lnWm05dWRDMXphWHBsUFNJeU1DSWdabWxzYkQwaUl6azVPU0lnWm05dWRDMW1ZVzFwYkhrOUlrZGxiM0puYVdFaUlHOXdZV05wZEhrOUlqQXVOeUkrQ2lBZ0lDQmFDaUFnUEM5MFpYaDBQZ284TDNOMlp6ND0ifQ=="
        );
    }
}
