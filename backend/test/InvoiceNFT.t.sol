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
    address private investor = makeAddr("investor");
    address private owner = address(this);
    InvoiceNFT.Company private creditorCompany;
    InvoiceNFT.Company private debtorCompany;
    InvoiceNFT.Company private investorCompany;
    InvoiceNFT.Invoice private invoice;

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
        investorCompany = InvoiceNFT.Company(
            investor,
            address(invoiceNFT),
            InvoiceNFT.CreditScore.C
        );
        debtorCompany = InvoiceNFT.Company(
            debtor,
            address(invoiceNFT),
            InvoiceNFT.CreditScore.B
        );
        creditorCompany = InvoiceNFT.Company(
            creditor,
            address(invoiceNFT),
            InvoiceNFT.CreditScore.A
        );
        invoice = InvoiceNFT.Invoice(
            "1234567890",
            "Activity",
            "USA",
            block.timestamp,
            1000,
            300,
            creditorCompany,
            debtorCompany,
            investorCompany,
            InvoiceNFT.InvoiceStatus.NEW
        );
    }

    function test_CreateInvoice_Success() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        assertEq(tokenId, 1);
        assertEq(invoiceNFT.balanceOf(creditor), 1);
    }

    function test_CreateInvoice_Success_Emit() public {
        vm.expectEmit();
        emit IERC721.Transfer(address(0), creditor, 1);
        invoiceNFT.createInvoice(creditor, invoice);
    }

    function test_CreateInvoice_Revert_NotOwner() public {
        vm.prank(debtor);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor)
        );
        invoiceNFT.createInvoice(creditor, invoice);
    }

    function test_CreateInvoice_MutipleInvoices() public {
        InvoiceNFT.Invoice memory invoice2 = InvoiceNFT.Invoice(
            "1111111111",
            "Military",
            "France",
            block.timestamp,
            3000,
            900,
            creditorCompany,
            debtorCompany,
            investorCompany,
            InvoiceNFT.InvoiceStatus.NEW
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
            abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0))
        );
        invoiceNFT.createInvoice(address(0), invoice);
    }
}

contract InvoiceNFTGetInvoiceTest is Test {
    InvoiceNFT private invoiceNFT;
    address private debtor = makeAddr("debtor");
    address private creditor = makeAddr("creditor");
    address private investor = makeAddr("investor");
    address private owner = address(this);
    InvoiceNFT.Company private creditorCompany;
    InvoiceNFT.Company private debtorCompany;
    InvoiceNFT.Company private investorCompany;
    InvoiceNFT.Invoice private invoice;

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
        investorCompany = InvoiceNFT.Company(
            investor,
            address(invoiceNFT),
            InvoiceNFT.CreditScore.C
        );
        debtorCompany = InvoiceNFT.Company(
            debtor,
            address(invoiceNFT),
            InvoiceNFT.CreditScore.B
        );
        creditorCompany = InvoiceNFT.Company(
            creditor,
            address(invoiceNFT),
            InvoiceNFT.CreditScore.A
        );
        invoice = InvoiceNFT.Invoice(
            "1234567890",
            "Activity",
            "USA",
            block.timestamp,
            1000,
            300,
            creditorCompany,
            debtorCompany,
            investorCompany,
            InvoiceNFT.InvoiceStatus.NEW
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
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor)
        );
        invoiceNFT.getInvoice(tokenId);
    }

    function testFuzz_GetInvoice_Revert_NotMinted(uint256 tokenId) public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, tokenId)
        );
        invoiceNFT.getInvoice(tokenId);
    }

    function testFuzz_GetInvoice_Revert_OneMinted(uint256 tokenId) public {
        invoiceNFT.createInvoice(creditor, invoice);
        if (tokenId != 1) {
            vm.expectRevert(
                abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, tokenId)
            );
            invoiceNFT.getInvoice(tokenId);
        }
    } 
}

contract InvoiceNFTTransferInvoiceTest is Test {
    InvoiceNFT private invoiceNFT;
    address private debtor = makeAddr("debtor");
    address private creditor = makeAddr("creditor");
    address private investor = makeAddr("investor");
    address private owner = address(this);
    InvoiceNFT.Company private creditorCompany;
    InvoiceNFT.Company private debtorCompany;
    InvoiceNFT.Company private investorCompany;
    InvoiceNFT.Invoice private invoice;

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
        investorCompany = InvoiceNFT.Company(
            investor,
            address(invoiceNFT),
            InvoiceNFT.CreditScore.C
        );
        debtorCompany = InvoiceNFT.Company(
            debtor,
            address(invoiceNFT),
            InvoiceNFT.CreditScore.B
        );
        creditorCompany = InvoiceNFT.Company(
            creditor,
            address(invoiceNFT),
            InvoiceNFT.CreditScore.A
        );
        
        invoice = InvoiceNFT.Invoice(
            "1234567890",
            "Activity",
            "USA",
            block.timestamp,
            1000,
            300,
            creditorCompany,
            debtorCompany,
            investorCompany,
            InvoiceNFT.InvoiceStatus.NEW
        );
    }

    function test_TransferInvoice_Success() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        invoiceNFT.transferInvoice(tokenId, investor);
        assertEq(invoiceNFT.ownerOf(tokenId), investor);
    }

    function test_TransferInvoice_Revert_NotOwner() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.prank(debtor);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, debtor)
        );
        invoiceNFT.transferInvoice(tokenId, investor);
    }

    function test_TransferInvoice_Revert_NotMinted() public {
        vm.expectRevert(
            abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 1)
        );
        invoiceNFT.transferInvoice(1, investor);
    }

    function test_TransferInvoice_ZeroAddress() public {
        uint256 tokenId = invoiceNFT.createInvoice(creditor, invoice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0))
        );
        invoiceNFT.transferInvoice(tokenId, address(0));
    }
    
}
