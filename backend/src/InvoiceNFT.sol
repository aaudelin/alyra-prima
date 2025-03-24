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
     * @notice Invoice struct to store the invoice details
     */
    struct Invoice {
        string id;
        uint256 dueDate;
        uint256 amount;
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

    constructor() ERC721("InvoiceNFT", "INV") {}

    function createInvoice(address to, Invoice calldata invoice) external onlyOwner {
        _tokenIdCounter++;
        _mint(to, _tokenIdCounter);
        _invoices[_tokenIdCounter] = invoice;
    }
}
