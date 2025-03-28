// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {InvoiceNFT} from "./InvoiceNFT.sol";
import {Collateral} from "./Collateral.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Prima {
    using Math for uint256;

    /**
     * @notice Mapping of debtor addresses to their invoices
     */
    mapping(address => uint256[]) private debtorInvoices;

    /**
     * @notice Mapping of creditor addresses to their invoices
     */
    mapping(address => uint256[]) private creditorInvoices;

    /**
     * @notice Mapping of investor addresses to their invoices
     */
    mapping(address => uint256[]) private investorInvoices;

    /**
     * @notice InvoiceNFT contract
     * @dev The InvoiceNFT contract is used to create and manage invoices
     */
    InvoiceNFT public invoiceNFT;

    /**
     * @notice Collateral contract
     * @dev The Collateral contract is used to manage collateral
     */
    Collateral public collateral;

    /**
     * @notice Constructor
     * @dev Initializes the InvoiceNFT and Collateral contracts as the owner of the contracts
     */
    constructor() {
        invoiceNFT = new InvoiceNFT(address(this));
        collateral = new Collateral(address(this));
    }

    error Prima_InvalidAmount(uint256 amount, uint256 minimumAmount, uint256 maximumAmount);

    function addCollateral(uint256 collateralAmount) external view {

    }

    function computeAmounts(uint256 amount, InvoiceNFT.CreditScore debtorCreditScore)
        public
        view
        virtual
        returns (uint256 minimumAmount, uint256 maximumAmount)
    {}

    function generateInvoice(InvoiceNFT.InvoiceParams calldata invoiceParams) external returns (uint256) {}

    function acceptInvoice(uint256 tokenId, uint256 collateralAmount) external {}

    function investInvoice(uint256 tokenId) external {}

    function payInvoice(uint256 tokenId) external {}

    function getInvoice(uint256 tokenId) external view returns (InvoiceNFT.Invoice memory) {}

    function getDebtorInvoices(address debtor) external view returns (uint256[] memory) {}

    function getCreditorInvoices(address creditor) external view returns (uint256[] memory) {}

    function getInvestorInvoices(address investor) external view returns (uint256[] memory) {}
}
