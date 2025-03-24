// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title InvoiceNFT
 * @notice InvoiceNFT is a contract that allows users to create and manage invoices as NFTs
 * @dev The contract inherits from openzeppelin's ERC721 contract
 */
contract InvoiceNFT is ERC721, Ownable {
    uint256 private _tokenIdCounter;

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

    mapping(uint256 => Invoice) private _invoices;

    constructor(address owner) ERC721("InvoiceNFT", "INV") Ownable(owner) {}

    function createInvoice(address to, Invoice calldata invoice) external onlyOwner returns (uint256) {
        _tokenIdCounter++;
        _mint(to, _tokenIdCounter);
        _setApprovalForAll(to, owner(), true);
        _invoices[_tokenIdCounter] = invoice;
        return _tokenIdCounter;
    }
}
