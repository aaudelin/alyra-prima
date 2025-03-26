// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/**
 * @title InvoiceNFT
 * @notice InvoiceNFT is a contract that allows users to create and manage invoices as NFTs
 * @dev The contract inherits from openzeppelin's ERC721 contract
 * @dev The contract is owned by the Parent contract (Prima) that is responsible for the minting and transfer of the NFTs
 */
contract InvoiceNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;
    mapping(uint256 => Invoice) private _invoices;

    /**
     * @notice CreditScore enum to store the credit score details
     */
    enum CreditScore {
        A,
        B,
        C,
        D,
        E,
        F
    }

    /**
     * @notice Company struct to store the company details
     */
    struct Company {
        address name;
        CreditScore creditScore;
    }

    /**
     * @notice Invoice struct to store the invoice details
     */
    struct Invoice {
        string id;
        string activity;
        string country;
        uint256 dueDate;
        uint256 amount;
        uint256 amountToPay;
        uint256 collateral;
        Company debtor;
        Company creditor;
        Company investor;
        InvoiceStatus invoiceStatus;
    }

    /**
     * @notice InvoiceParams struct to request the creation of an invoice
     */
    struct InvoiceParams {
        string id;
        string activity;
        string country;
        uint256 dueDate;
        uint256 amount;
        uint256 amountToPay;
        Company debtor;
        Company creditor;
    }

    /**
     * @notice Invoice status enum
     * @dev NEW: new generated invoice
     * @dev ACCEPTED: invoice has been accepted by the debtor
     * @dev IN_PROGRESS: invoice has an investor
     * @dev PAID: invoice is paid by the debtor
     * @dev OVERDUE: invoice is overdue
     */
    enum InvoiceStatus {
        NEW,
        ACCEPTED,
        IN_PROGRESS,
        PAID,
        OVERDUE
    }

    error InvoiceNFT_WrongInvoiceStatus(uint256 tokenId, InvoiceStatus actual);

    event StatusChanged(uint256 tokenId, InvoiceStatus newStatus);

    constructor(address owner) ERC721("Prima Invoice", "PIT") Ownable(owner) {}

    /**
     * @notice Create a new Invoice as a NFT
     * @dev Only the owner can create a new invoice
     * @dev The invoice is minted to the Creditor
     * @param to: address of the Creditor
     * @param invoiceParams: Invoice struct containing the invoice details
     * @return tokenId: tokenId of the newly created invoice
     */
    function createInvoice(address to, InvoiceParams calldata invoiceParams) external onlyOwner returns (uint256) {
        require(to != address(0), IERC721Errors.ERC721InvalidReceiver(address(0)));
        _tokenIdCounter++;
        _safeMint(to, _tokenIdCounter);
        _invoices[_tokenIdCounter] = Invoice(
            invoiceParams.id,
            invoiceParams.activity,
            invoiceParams.country,
            invoiceParams.dueDate,
            invoiceParams.amount,
            invoiceParams.amountToPay,
            0,
            invoiceParams.debtor,
            invoiceParams.creditor,
            Company(address(0), CreditScore.A),
            InvoiceStatus.NEW
        );
        emit StatusChanged(_tokenIdCounter, InvoiceStatus.NEW);
        return _tokenIdCounter;
    }

    /**
     * @notice Get the invoice details
     * @dev Only the owner can get the invoice details
     * @dev The invoice must be minted
     * @param tokenId: tokenId of the invoice
     * @return invoice: Invoice struct containing the invoice details
     */
    function getInvoice(uint256 tokenId) external view onlyOwner returns (Invoice memory) {
        _requireOwned(tokenId);
        return _invoices[tokenId];
    }

    /**
     * @notice Update the collateral of the invoice
     * @dev Only the owner can update the collateral
     * @param tokenId: tokenId of the invoice
     * @param collateral: new collateral of the invoice
     */
    function acceptInvoice(uint256 tokenId, uint256 collateral) external onlyOwner {
        _requireOwned(tokenId);
        require(
            _invoices[tokenId].invoiceStatus == InvoiceStatus.NEW,
            InvoiceNFT_WrongInvoiceStatus(tokenId, _invoices[tokenId].invoiceStatus)
        );
        _invoices[tokenId].collateral = collateral;
        _invoices[tokenId].invoiceStatus = InvoiceStatus.ACCEPTED;
        emit StatusChanged(tokenId, InvoiceStatus.ACCEPTED);
    }

    /**
     * @notice Transfer the invoice when an Investor invests
     * @dev Only the owner can transfer the invoice
     * @param tokenId: tokenId of the invoice
     * @param investor: Investor struct containing the investor details
     */
    function investInvoice(uint256 tokenId, Company memory investor) external onlyOwner {
        _requireOwned(tokenId);
        require(
            _invoices[tokenId].invoiceStatus == InvoiceStatus.ACCEPTED,
            InvoiceNFT_WrongInvoiceStatus(tokenId, _invoices[tokenId].invoiceStatus)
        );
        _transfer(_ownerOf(tokenId), investor.name, tokenId);
        _invoices[tokenId].investor = investor;
        _invoices[tokenId].invoiceStatus = InvoiceStatus.IN_PROGRESS;
        emit StatusChanged(tokenId, InvoiceStatus.IN_PROGRESS);
    }

    /**
     * @notice Pay the invoice
     * @dev Only the Owner can pay the invoice
     * @param tokenId: tokenId of the invoice
     * @param success: boolean to indicate if the payment was successful
     */
    function payInvoice(uint256 tokenId, bool success) external onlyOwner {
        _requireOwned(tokenId);
        require(
            _invoices[tokenId].invoiceStatus == InvoiceStatus.IN_PROGRESS || _invoices[tokenId].invoiceStatus == InvoiceStatus.OVERDUE,
            InvoiceNFT_WrongInvoiceStatus(tokenId, _invoices[tokenId].invoiceStatus)
        );
        _invoices[tokenId].invoiceStatus = success ? InvoiceStatus.PAID : InvoiceStatus.OVERDUE;
        emit StatusChanged(tokenId, _invoices[tokenId].invoiceStatus);
    }
}