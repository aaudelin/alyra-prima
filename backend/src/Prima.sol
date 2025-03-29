// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {InvoiceNFT} from "./InvoiceNFT.sol";
import {Collateral} from "./Collateral.sol";
import {PrimaToken} from "./PrimaToken.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title Prima
 * @notice Prima is the main contract that manages the invoice financing system
 * @dev This contract is responsible for managing the interaction between InvoiceNFT, Collateral and PrimaToken contracts
 * @author @aaudelin
 */
contract Prima {
    using Math for uint256;

    /**
     * @notice Mapping of debtor addresses to their invoices
     */
    mapping(address => uint256[]) private _debtorInvoices;

    /**
     * @notice Mapping of creditor addresses to their invoices
     */
    mapping(address => uint256[]) private _creditorInvoices;

    /**
     * @notice Mapping of investor addresses to their invoices
     */
    mapping(address => uint256[]) private _investorInvoices;

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
     * @notice PrimaToken contract
     * @dev The PrimaToken contract is used to manage the Prima token
     */
    PrimaToken public primaToken;

    /**
     * @notice Error for invalid invoice amount to pay
     * @param amount The amount of the invoice
     * @param minimumAmount The minimum amount of the invoice
     * @param maximumAmount The maximum amount of the invoice
     */
    error Prima_InvalidInvoiceAmountToPay(uint256 amount, uint256 minimumAmount, uint256 maximumAmount);

    /**
     * @notice Error for invalid invoice amount
     * @param amount The amount of the invoice
     * @param amountToPay The amount to pay of the invoice
     */
    error Prima_InvalidInvoiceAmount(uint256 amount, uint256 amountToPay);

    /**
     * @notice Error for invalid due date
     * @param dueDate The due date of the invoice
     */
    error Prima_InvalidDueDate(uint256 dueDate);

    /**
     * @notice Error for invalid zero address
     */
    error Prima_InvalidZeroAddress();

    /**
     * @notice Error for invalid invoice id
     */
    error Prima_InvalidInvoiceId();

    /**
     * @notice Constructor
     * @dev Initializes the InvoiceNFT and Collateral contracts as the owner of the contracts
     * @param invoiceNFTAddress The address of the InvoiceNFT contract
     * @param collateralAddress The address of the Collateral contract
     * @param primaTokenAddress The address of the PrimaToken contract
     */
    constructor(address invoiceNFTAddress, address collateralAddress, address primaTokenAddress) {
        invoiceNFT = InvoiceNFT(invoiceNFTAddress);
        collateral = Collateral(collateralAddress);
        primaToken = PrimaToken(primaTokenAddress);
    }

    /**
     * @notice Add collateral to the debtor
     * @dev This function allows the debtor to add collateral to their account
     * @param collateralAmount The amount of collateral to add
     */
    function addCollateral(uint256 collateralAmount) external {
        primaToken.transferFrom(msg.sender, address(collateral), collateralAmount);
        collateral.deposit(msg.sender, collateralAmount);
    }

    /**
     * @notice Compute the minimum and maximum amounts for an invoice
     * @dev This function computes the minimum and maximum amounts for an invoice based on the debtor's credit score
     * @dev This function is useful before creating an invoice
     * @param amount The amount of the invoice
     * @param debtorCreditScore The credit score of the debtor
     * @return minimumAmount The minimum amount of the invoice
     * @return maximumAmount The maximum amount of the invoice
     */
    function computeAmounts(uint256 amount, InvoiceNFT.CreditScore debtorCreditScore)
        public
        view
        virtual
        returns (uint256 minimumAmount, uint256 maximumAmount)
    {
        if (debtorCreditScore == InvoiceNFT.CreditScore.A) {
            (, minimumAmount) = (amount * 95).tryDiv(100);
            (, maximumAmount) = (amount * 100).tryDiv(100);
        } else if (debtorCreditScore == InvoiceNFT.CreditScore.B) {
            (, minimumAmount) = (amount * 90).tryDiv(100);
            (, maximumAmount) = (amount * 95).tryDiv(100);
        } else if (debtorCreditScore == InvoiceNFT.CreditScore.C) {
            (, minimumAmount) = (amount * 85).tryDiv(100);
            (, maximumAmount) = (amount * 90).tryDiv(100);
        } else if (debtorCreditScore == InvoiceNFT.CreditScore.D) {
            (, minimumAmount) = (amount * 80).tryDiv(100);
            (, maximumAmount) = (amount * 85).tryDiv(100);
        } else if (debtorCreditScore == InvoiceNFT.CreditScore.E) {
            (, minimumAmount) = (amount * 75).tryDiv(100);
            (, maximumAmount) = (amount * 80).tryDiv(100);
        } else {
            (, minimumAmount) = (amount * 70).tryDiv(100);
            (, maximumAmount) = (amount * 75).tryDiv(100);
        }
    }

    function generateInvoice(InvoiceNFT.InvoiceParams calldata invoiceParams) external returns (uint256) {
        require(bytes(invoiceParams.id).length > 0, Prima_InvalidInvoiceId());
        require(invoiceParams.dueDate > block.timestamp, Prima_InvalidDueDate(invoiceParams.dueDate));
        require(
            invoiceParams.amount > invoiceParams.amountToPay,
            Prima_InvalidInvoiceAmount(invoiceParams.amount, invoiceParams.amountToPay)
        );
        require(invoiceParams.debtor.name != address(0), Prima_InvalidZeroAddress());
        require(invoiceParams.creditor.name != address(0), Prima_InvalidZeroAddress());
        (uint256 minimumAmount, uint256 maximumAmount) =
            computeAmounts(invoiceParams.amount, invoiceParams.debtor.creditScore);
        require(
            invoiceParams.amountToPay > 0 && invoiceParams.amountToPay >= minimumAmount
                && invoiceParams.amountToPay <= maximumAmount,
            Prima_InvalidInvoiceAmountToPay(invoiceParams.amountToPay, minimumAmount, maximumAmount)
        );
        return invoiceNFT.createInvoice(invoiceParams.creditor.name, invoiceParams);
    }

    function acceptInvoice(uint256 tokenId, uint256 collateralAmount) external {}

    function investInvoice(uint256 tokenId) external {}

    function payInvoice(uint256 tokenId) external {}

    function getInvoice(uint256 tokenId) external view returns (InvoiceNFT.Invoice memory) {}

    function getDebtorInvoices(address debtor) external view returns (uint256[] memory) {}

    function getCreditorInvoices(address creditor) external view returns (uint256[] memory) {}

    function getInvestorInvoices(address investor) external view returns (uint256[] memory) {}
}
