// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title InvoiceNFT
 * @notice InvoiceNFT is a contract that allows users to create and manage invoices as NFTs
 * @dev The contract inherits from openzeppelin's ERC721 contract
 * @dev The contract is owned by the Parent contract (Prima) that is responsible for the minting and transfer of the NFTs
 * @author @aaudelin
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
     * @param name address of the company
     * @param creditScore credit score of the company
     */
    struct Company {
        address name;
        CreditScore creditScore;
    }

    /**
     * @notice Invoice struct to store the invoice details
     * @param id id of the invoice
     * @param activity activity field related to the invoice (e.g. "Export of goods")
     * @param country country for the taxes
     * @param dueDate due
     * @param amount amount in token that must be paid byt the debtor (in PrimaToken only)
     * @param amountToPay amount to pay of the invoice by the investor
     * @param collateral collateral amount associated by the debtor
     * @param debtor debtor company details
     * @param creditor creditor company details
     * @param investor investor company details
     * @param invoiceStatus status of the invoice
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
     * @param id id of the invoice
     * @param activity activity field related to the invoice (e.g. "Export of goods")
     * @param country country for the taxes
     * @param dueDate due
     * @param amount amount in token that must be paid byt the debtor (in PrimaToken only)
     * @param amountToPay amount to pay of the invoice by the investor
     * @param debtor debtor company details
     * @param creditor creditor company details
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
     * @dev NEW new generated invoice
     * @dev ACCEPTED invoice has been accepted by the debtor
     * @dev IN_PROGRESS invoice has an investor
     * @dev PAID invoice is paid by the debtor
     * @dev OVERDUE invoice is overdue
     */
    enum InvoiceStatus {
        NEW,
        ACCEPTED,
        IN_PROGRESS,
        PAID,
        OVERDUE
    }

    error InvoiceNFT_WrongInvoiceStatus(uint256 tokenId, InvoiceStatus actual);

    event InvoiceNFT_StatusChanged(uint256 tokenId, InvoiceStatus newStatus);

    constructor(address owner) ERC721("Prima Invoice", "PIT") Ownable(owner) {}

    /**
     * @notice Create a new Invoice as a NFT
     * @dev Only the owner can create a new invoice
     * @dev The invoice is minted to the Creditor
     * @param to The address of the Creditor
     * @param invoiceParams The Invoice struct containing the invoice details
     * @return tokenId The tokenId of the newly created invoice
     */
    function createInvoice(address to, InvoiceParams calldata invoiceParams) external onlyOwner returns (uint256) {
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
        emit InvoiceNFT_StatusChanged(_tokenIdCounter, InvoiceStatus.NEW);
        return _tokenIdCounter;
    }

    /**
     * @notice Get the invoice details
     * @dev Only the owner can get the invoice details
     * @dev The invoice must be minted
     * @param tokenId The tokenId of the invoice
     * @return invoice The Invoice struct containing the invoice details
     */
    function getInvoice(uint256 tokenId) external view onlyOwner returns (Invoice memory) {
        _requireOwned(tokenId);
        return _invoices[tokenId];
    }

    /**
     * @notice Update the collateral of the invoice
     * @dev Only the owner can update the collateral
     * @param tokenId The tokenId of the invoice
     * @param collateral The new collateral of the invoice
     */
    function acceptInvoice(uint256 tokenId, uint256 collateral) external onlyOwner {
        _requireOwned(tokenId);
        require(
            _invoices[tokenId].invoiceStatus == InvoiceStatus.NEW,
            InvoiceNFT_WrongInvoiceStatus(tokenId, _invoices[tokenId].invoiceStatus)
        );
        _invoices[tokenId].collateral = collateral;
        _invoices[tokenId].invoiceStatus = InvoiceStatus.ACCEPTED;
        emit InvoiceNFT_StatusChanged(tokenId, InvoiceStatus.ACCEPTED);
    }

    /**
     * @notice Transfer the invoice when an Investor invests
     * @dev Only the owner can transfer the invoice
     * @param tokenId The tokenId of the invoice
     * @param investor The Investor struct containing the investor details
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
        emit InvoiceNFT_StatusChanged(tokenId, InvoiceStatus.IN_PROGRESS);
    }

    /**
     * @notice Pay the invoice
     * @dev Only the Owner can pay the invoice
     * @param tokenId The tokenId of the invoice
     * @param success The boolean to indicate if the payment was successful
     */
    function payInvoice(uint256 tokenId, bool success) external onlyOwner {
        _requireOwned(tokenId);
        require(
            _invoices[tokenId].invoiceStatus == InvoiceStatus.IN_PROGRESS
                || _invoices[tokenId].invoiceStatus == InvoiceStatus.OVERDUE,
            InvoiceNFT_WrongInvoiceStatus(tokenId, _invoices[tokenId].invoiceStatus)
        );
        _invoices[tokenId].invoiceStatus = success ? InvoiceStatus.PAID : InvoiceStatus.OVERDUE;
        emit InvoiceNFT_StatusChanged(tokenId, _invoices[tokenId].invoiceStatus);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function _getSVG() internal pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded =
            "PHN2ZyB3aWR0aD0iODAwIiBoZWlnaHQ9IjYwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8IS0tIEJhY2tncm91bmQgLS0+CiAgPGRlZnM+CiAgICA8bGluZWFyR3JhZGllbnQgaWQ9ImJnR3JhZGllbnQiIHgxPSIwIiB5MT0iMCIgeDI9IjAiIHkyPSIxIj4KICAgICAgPHN0b3Agb2Zmc2V0PSIwJSIgc3RvcC1jb2xvcj0iI2U2ZTFmNSIvPgogICAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiNjOWJkZTUiLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgPC9kZWZzPgogIDxyZWN0IHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIGZpbGw9InVybCgjYmdHcmFkaWVudCkiLz4KCiAgPCEtLSBUaXRsZSAtLT4KICA8dGV4dCB4PSI1MCUiIHk9IjEwMCIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZm9udC1zaXplPSI2NCIgZm9udC1mYW1pbHk9InNlcmlmIiBmaWxsPSIjMWExYTFhIiBzdHlsZT0iZm9udC1zdHlsZTogaXRhbGljOyBsZXR0ZXItc3BhY2luZzogMnB4OyI+CiAgICBQcmltYQogIDwvdGV4dD4KCiAgPCEtLSBJbnZvaWNlIExhYmVsIC0tPgogIDx0ZXh0IHg9IjUwJSIgeT0iMTYwIiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmb250LXNpemU9IjI0IiBmb250LWZhbWlseT0iR2VvcmdpYSIgZmlsbD0iI2E2N2MwMCIgbGV0dGVyLXNwYWNpbmc9IjMiPgogICAgSU5WT0lDRQogIDwvdGV4dD4KCiAgPCEtLSBJbnZvaWNlIEJvZHkgLS0+CiAgPHJlY3QgeD0iMTAwIiB5PSIyMDAiIHdpZHRoPSI2MDAiIGhlaWdodD0iMzAwIiByeD0iMjAiIHJ5PSIyMCIgZmlsbD0iI2ZmZmZmZiIgc3Ryb2tlPSIjZDRjMmYwIiBzdHJva2Utd2lkdGg9IjIiLz4KICAKICA8IS0tIFRhYmxlIEhlYWRpbmdzIC0tPgoKICA8IS0tIERpdmlkZXIgTGluZSAtLT4KICA8bGluZSB4MT0iMTIwIiB5MT0iMjQ1IiB4Mj0iNjgwIiB5Mj0iMjQ1IiBzdHJva2U9IiNjY2MiIHN0cm9rZS13aWR0aD0iMSIvPgoKICA8IS0tIEZvb3RlciBtb25vZ3JhbSAtLT4KICA8dGV4dCB4PSI3MjAiIHk9IjU1MCIgZm9udC1zaXplPSIyMCIgZmlsbD0iIzk5OSIgZm9udC1mYW1pbHk9Ikdlb3JnaWEiIG9wYWNpdHk9IjAuNyI+CiAgICBaCiAgPC90ZXh0Pgo8L3N2Zz4=";
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        Invoice memory invoice = _invoices[tokenId];
        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"Prima Invoice ',
                            invoice.id,
                            '", "description":"Invoices generated by Prima", ',
                            '"attributes":[{"trait_type":"Id","value":"',
                            invoice.id,
                            '"}, ',
                            '{"trait_type":"Activity","value":"',
                            invoice.activity,
                            '"}, ',
                            '{"trait_type":"Country","value":"',
                            invoice.country,
                            '"}, ',
                            '{"trait_type":"Due Date","value":"',
                            Strings.toString(invoice.dueDate),
                            '"}, ',
                            '{"trait_type":"Amount","value":"',
                            Strings.toString(invoice.amount),
                            '"}, ',
                            '{"trait_type":"Amount To Pay","value":"',
                            Strings.toString(invoice.amountToPay),
                            '"}], ',
                            '"image":"',
                            _getSVG(),
                            '"}'
                        )
                    )
                )
            )
        );
    }
}
