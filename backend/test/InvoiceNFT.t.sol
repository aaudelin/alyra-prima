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
        creditorCompany = InvoiceNFT.Company(
            creditor,
            InvoiceNFT.CreditScore.A
        );
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890",
            "Activity",
            "USA",
            block.timestamp,
            1000,
            900,
            debtorCompany,
            creditorCompany
        );
    }

    function test_CreateInvoice_Success() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        assertEq(tokenId, 1);
        assertEq(invoiceNFT.balanceOf(creditor), 1);
        assertEq(invoiceNFT.getInvoice(tokenId).id, invoice.id);
        assertEq(
            uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus),
            uint256(InvoiceNFT.InvoiceStatus.NEW)
        );
        assertEq(invoiceNFT.getInvoice(tokenId).collateral, 0);
        assertEq(invoiceNFT.getInvoice(tokenId).investor.name, address(0));
    }

    function test_CreateInvoice_Success_Emit() public {
        vm.expectEmit();
        emit IERC721.Transfer(address(0), creditor, 1);
        invoiceNFT.createInvoice(creditor, invoice);
    }

    function test_CreateInvoice_Revert_NotOwner() public {
        vm.prank(debtor);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                debtor
            )
        );
        invoiceNFT.createInvoice(creditor, invoice);
    }

    function test_CreateInvoice_MutipleInvoices() public {
        InvoiceNFT.InvoiceParams memory invoice2 = InvoiceNFT.InvoiceParams(
            "1111111111",
            "Military",
            "France",
            block.timestamp,
            3000,
            900,
            debtorCompany,
            creditorCompany
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
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InvalidReceiver.selector,
                address(0)
            )
        );
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
        creditorCompany = InvoiceNFT.Company(
            creditor,
            InvoiceNFT.CreditScore.A
        );
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890",
            "Activity",
            "USA",
            block.timestamp,
            1000,
            900,
            debtorCompany,
            creditorCompany
        );
    }

    function test_GetInvoice_Success() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        InvoiceNFT.Invoice memory retrievedInvoice = invoiceNFT.getInvoice(
            tokenId
        );
        assertEq(retrievedInvoice.id, invoice.id);
    }

    function test_GetInvoice_Revert_NotOwner() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.prank(debtor);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                debtor
            )
        );
        invoiceNFT.getInvoice(tokenId);
    }

    function testFuzz_GetInvoice_Revert_NotMinted(uint256 tokenId) public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721NonexistentToken.selector,
                tokenId
            )
        );
        invoiceNFT.getInvoice(tokenId);
    }

    function testFuzz_GetInvoice_Revert_OneMinted(uint256 tokenId) public {
        invoiceNFT.createInvoice(creditor, invoice);
        if (tokenId != 1) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IERC721Errors.ERC721NonexistentToken.selector,
                    tokenId
                )
            );
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
        creditorCompany = InvoiceNFT.Company(
            creditor,
            InvoiceNFT.CreditScore.A
        );
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890",
            "Activity",
            "USA",
            block.timestamp,
            1000,
            900,
            debtorCompany,
            creditorCompany
        );
    }

    function test_AcceptInvoice_SuccessNoCollateral() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        assertEq(
            uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus),
            uint256(InvoiceNFT.InvoiceStatus.ACCEPTED)
        );
        assertEq(invoiceNFT.getInvoice(tokenId).collateral, 0);
    }

    function test_AcceptInvoice_SuccessWithCollateral() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 100);
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        assertEq(
            uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus),
            uint256(InvoiceNFT.InvoiceStatus.ACCEPTED)
        );
        assertEq(invoiceNFT.getInvoice(tokenId).collateral, 100);
    }

    function test_AcceptInvoice_Revert_NotOwner() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.prank(debtor);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                debtor
            )
        );
        invoiceNFT.acceptInvoice(tokenId, 0);
    }

    function test_AcceptInvoice_Revert_NotMinted() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721NonexistentToken.selector,
                1
            )
        );
        invoiceNFT.acceptInvoice(1, 0);
    }

    function test_AcceptInvoice_Revert_WrongStatus() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                InvoiceNFT.InvoiceNFT_WrongInvoiceStatus.selector,
                tokenId,
                uint256(InvoiceNFT.InvoiceStatus.ACCEPTED)
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
        creditorCompany = InvoiceNFT.Company(
            creditor,
            InvoiceNFT.CreditScore.A
        );
        investorCompany = InvoiceNFT.Company(
            investor,
            InvoiceNFT.CreditScore.A
        );
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890",
            "Activity",
            "USA",
            block.timestamp,
            1000,
            300,
            debtorCompany,
            creditorCompany
        );
    }

    function test_InvestInvoice_Success() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        invoiceNFT.acceptInvoice(tokenId, 0);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        assertEq(invoiceNFT.ownerOf(tokenId), investor);
        assertEq(invoiceNFT.getInvoice(tokenId).investor.name, investor);
        assertEq(
            uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus),
            uint256(InvoiceNFT.InvoiceStatus.IN_PROGRESS)
        );
    }

    function test_InvestInvoice_Revert_NotOwner() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        vm.prank(debtor);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                debtor
            )
        );
        invoiceNFT.investInvoice(tokenId, investorCompany);
    }

    function test_InvestInvoice_Revert_NotMinted() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721NonexistentToken.selector,
                1
            )
        );
        invoiceNFT.investInvoice(1, investorCompany);
    }

    function test_InvestInvoice_ZeroAddress() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InvalidReceiver.selector,
                address(0)
            )
        );
        invoiceNFT.investInvoice(
            tokenId,
            InvoiceNFT.Company(address(0), InvoiceNFT.CreditScore.A)
        );
    }

    function test_InvestInvoice_Revert_WrongStatus() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.expectRevert(abi.encodeWithSelector(InvoiceNFT.InvoiceNFT_WrongInvoiceStatus.selector, tokenId, uint256(InvoiceNFT.InvoiceStatus.NEW)));
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
        creditorCompany = InvoiceNFT.Company(
            creditor,
            InvoiceNFT.CreditScore.A
        );
        investorCompany = InvoiceNFT.Company(
            investor,
            InvoiceNFT.CreditScore.A
        );
        invoice = InvoiceNFT.InvoiceParams(
            "1234567890",
            "Activity",
            "USA",
            block.timestamp,
            1000,
            300,
            debtorCompany,
            creditorCompany
        );
    }

    function test_PayInvoice_Success_PaymentSuccess() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        invoiceNFT.payInvoice(tokenId, true);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.PAID));
    }


    function test_PayInvoice_Success_PaymentSuccessOverdue() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        invoiceNFT.payInvoice(tokenId, false);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.OVERDUE));
        invoiceNFT.payInvoice(tokenId, true);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.PAID));
    }

    function test_PayInvoice_Success_PaymentFailed() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        invoiceNFT.payInvoice(tokenId, false);
        assertEq(uint256(invoiceNFT.getInvoice(tokenId).invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.OVERDUE));
    }

    function test_PayInvoice_Revert_NotOwner() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        invoiceNFT.investInvoice(tokenId, investorCompany);
        vm.prank(debtor);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                debtor
            )
        );
        invoiceNFT.payInvoice(tokenId, true);
    }

    function test_PayInvoice_Revert_NotMinted() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721NonexistentToken.selector,
                1
            )
        );
        invoiceNFT.payInvoice(1, true);
    }

    function test_PayInvoice_Revert_WrongStatus() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.acceptInvoice(tokenId, 0);
        vm.expectRevert(abi.encodeWithSelector(InvoiceNFT.InvoiceNFT_WrongInvoiceStatus.selector, tokenId, uint256(InvoiceNFT.InvoiceStatus.ACCEPTED)));
        invoiceNFT.payInvoice(tokenId, true);
    }
}
