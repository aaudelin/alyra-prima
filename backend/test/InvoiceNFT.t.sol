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
        assertEq(
            invoiceNFT.tokenURI(tokenId),
            "data:application/json;base64,eyJuYW1lIjoiUHJpbWEgSW52b2ljZSAxMjM0NTY3ODkwIiwgImRlc2NyaXB0aW9uIjoiSW52b2ljZXMgZ2VuZXJhdGVkIGJ5IFByaW1hIiwgImF0dHJpYnV0ZXMiOlt7InRyYWl0X3R5cGUiOiJJZCIsInZhbHVlIjoiMTIzNDU2Nzg5MCJ9LCB7InRyYWl0X3R5cGUiOiJBY3Rpdml0eSIsInZhbHVlIjoiQWN0aXZpdHkifSwgeyJ0cmFpdF90eXBlIjoiQ291bnRyeSIsInZhbHVlIjoiVVNBIn0sIHsidHJhaXRfdHlwZSI6IkR1ZSBEYXRlIiwidmFsdWUiOiIxIn0sIHsidHJhaXRfdHlwZSI6IkFtb3VudCIsInZhbHVlIjoiMTAwMCJ9LCB7InRyYWl0X3R5cGUiOiJBbW91bnQgVG8gUGF5IiwidmFsdWUiOiIzMDAifV0sICJpbWFnZSI6ImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjNhV1IwYUQwaU9EQXdJaUJvWldsbmFIUTlJall3TUNJZ2VHMXNibk05SW1oMGRIQTZMeTkzZDNjdWR6TXViM0puTHpJd01EQXZjM1puSWo0S0lDQThJUzB0SUVKaFkydG5jbTkxYm1RZ0xTMCtDaUFnUEdSbFpuTStDaUFnSUNBOGJHbHVaV0Z5UjNKaFpHbGxiblFnYVdROUltSm5SM0poWkdsbGJuUWlJSGd4UFNJd0lpQjVNVDBpTUNJZ2VESTlJakFpSUhreVBTSXhJajRLSUNBZ0lDQWdQSE4wYjNBZ2IyWm1jMlYwUFNJd0pTSWdjM1J2Y0MxamIyeHZjajBpSTJVMlpURm1OU0l2UGdvZ0lDQWdJQ0E4YzNSdmNDQnZabVp6WlhROUlqRXdNQ1VpSUhOMGIzQXRZMjlzYjNJOUlpTmpPV0prWlRVaUx6NEtJQ0FnSUR3dmJHbHVaV0Z5UjNKaFpHbGxiblErQ2lBZ1BDOWtaV1p6UGdvZ0lEeHlaV04wSUhkcFpIUm9QU0l4TURBbElpQm9aV2xuYUhROUlqRXdNQ1VpSUdacGJHdzlJblZ5YkNnalltZEhjbUZrYVdWdWRDa2lMejRLQ2lBZ1BDRXRMU0JVYVhSc1pTQXRMVDRLSUNBOGRHVjRkQ0I0UFNJMU1DVWlJSGs5SWpFd01DSWdkR1Y0ZEMxaGJtTm9iM0k5SW0xcFpHUnNaU0lnWm05dWRDMXphWHBsUFNJMk5DSWdabTl1ZEMxbVlXMXBiSGs5SW5ObGNtbG1JaUJtYVd4c1BTSWpNV0V4WVRGaElpQnpkSGxzWlQwaVptOXVkQzF6ZEhsc1pUb2dhWFJoYkdsak95QnNaWFIwWlhJdGMzQmhZMmx1WnpvZ01uQjRPeUkrQ2lBZ0lDQlFjbWx0WVFvZ0lEd3ZkR1Y0ZEQ0S0NpQWdQQ0V0TFNCSmJuWnZhV05sSUV4aFltVnNJQzB0UGdvZ0lEeDBaWGgwSUhnOUlqVXdKU0lnZVQwaU1UWXdJaUIwWlhoMExXRnVZMmh2Y2owaWJXbGtaR3hsSWlCbWIyNTBMWE5wZW1VOUlqSTBJaUJtYjI1MExXWmhiV2xzZVQwaVIyVnZjbWRwWVNJZ1ptbHNiRDBpSTJFMk4yTXdNQ0lnYkdWMGRHVnlMWE53WVdOcGJtYzlJak1pUGdvZ0lDQWdTVTVXVDBsRFJRb2dJRHd2ZEdWNGRENEtDaUFnUENFdExTQkpiblp2YVdObElFSnZaSGtnTFMwK0NpQWdQSEpsWTNRZ2VEMGlNVEF3SWlCNVBTSXlNREFpSUhkcFpIUm9QU0kyTURBaUlHaGxhV2RvZEQwaU16QXdJaUJ5ZUQwaU1qQWlJSEo1UFNJeU1DSWdabWxzYkQwaUkyWm1abVptWmlJZ2MzUnliMnRsUFNJalpEUmpNbVl3SWlCemRISnZhMlV0ZDJsa2RHZzlJaklpTHo0S0lDQUtJQ0E4SVMwdElGUmhZbXhsSUVobFlXUnBibWR6SUMwdFBnb0tJQ0E4SVMwdElFUnBkbWxrWlhJZ1RHbHVaU0F0TFQ0S0lDQThiR2x1WlNCNE1UMGlNVEl3SWlCNU1UMGlNalExSWlCNE1qMGlOamd3SWlCNU1qMGlNalExSWlCemRISnZhMlU5SWlOalkyTWlJSE4wY205clpTMTNhV1IwYUQwaU1TSXZQZ29LSUNBOElTMHRJRVp2YjNSbGNpQnRiMjV2WjNKaGJTQXRMVDRLSUNBOGRHVjRkQ0I0UFNJM01qQWlJSGs5SWpVMU1DSWdabTl1ZEMxemFYcGxQU0l5TUNJZ1ptbHNiRDBpSXprNU9TSWdabTl1ZEMxbVlXMXBiSGs5SWtkbGIzSm5hV0VpSUc5d1lXTnBkSGs5SWpBdU55SStDaUFnSUNCYUNpQWdQQzkwWlhoMFBnbzhMM04yWno0PSJ9"
        );
    }
}
