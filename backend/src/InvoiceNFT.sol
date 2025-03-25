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
        address collateralAccount;
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
        uint256 collateral;
        Company debtor;
        Company creditor;
        Company investor;
        InvoiceStatus invoiceStatus;
    }

    /**
     * @notice Invoice status enum 
     * @dev NEW: new generated invoice
     * @dev IN_PROGRESS: invoice has an investor
     * @dev PAID: invoice is paid by the debtor
     * @dev OVERDUE: invoice is overdue
     */
    enum InvoiceStatus {
        NEW,
        IN_PROGRESS,
        PAID,
        OVERDUE
    }

    constructor(address owner) ERC721("Prima Invoice", "PIT") Ownable(owner) {}

    /**
     * @notice Create a new Invoice as a NFT
     * @dev Only the owner can create a new invoice
     * @dev The invoice is minted to the Creditor
     * @param to: address of the Creditor
     * @param invoice: Invoice struct containing the invoice details
     * @return tokenId: tokenId of the newly created invoice
     */
    function createInvoice(address to, Invoice calldata invoice) external onlyOwner returns (uint256) {
        require(to != address(0), IERC721Errors.ERC721InvalidReceiver(address(0)));
        _tokenIdCounter++;
        _safeMint(to, _tokenIdCounter);
        _invoices[_tokenIdCounter] = invoice;
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
     * @notice Transfer the invoice when an Investor invests
     * @dev Only the owner can transfer the invoice
     * @param tokenId: tokenId of the invoice
     * @param to: address of the new Investor
     */
    function transferInvoice(uint256 tokenId, address to) external onlyOwner {
        require(to != address(0), IERC721Errors.ERC721InvalidReceiver(address(0)));
        _requireOwned(tokenId);
        _update(to, tokenId, address(0));
    }
}