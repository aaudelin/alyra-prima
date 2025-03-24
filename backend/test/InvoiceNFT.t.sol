// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";

contract InvoiceNFTTest is Test {
    InvoiceNFT private invoiceNFT;
    address private debtor = makeAddr("debtor");
    address private creditor = makeAddr("creditor");
    address private investor = makeAddr("investor");
    address private owner = address(this);

    function setUp() public {
        invoiceNFT = new InvoiceNFT(owner);
    }

    function test_CreateInvoice() public {
        InvoiceNFT.Company memory creditorCompany = InvoiceNFT.Company(creditor, address(invoiceNFT), InvoiceNFT.CreditScore.A);
        InvoiceNFT.Company memory debtorCompany = InvoiceNFT.Company(debtor, address(invoiceNFT), InvoiceNFT.CreditScore.B);
        InvoiceNFT.Company memory investorCompany = InvoiceNFT.Company(investor, address(invoiceNFT), InvoiceNFT.CreditScore.C);
        uint256 tokenId = invoiceNFT.createInvoice(
            creditor,
            InvoiceNFT.Invoice(
                "1234567890",
                "Activity",
                "USA",
                100,
                100,
                100,
                creditorCompany,
                debtorCompany,
                investorCompany,
                InvoiceNFT.InvoiceStatus.NEW
            )
        );
        assertEq(invoiceNFT.ownerOf(tokenId), creditor);
        assertEq(tokenId, 1);
        assertEq(invoiceNFT.balanceOf(creditor), 1);
        assertEq(invoiceNFT.isApprovedForAll(creditor, owner), true);
    }
}
