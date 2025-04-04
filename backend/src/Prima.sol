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
     * @notice Mapping of debtor addresses to their active collateral
     */
    mapping(address => uint256) private _activeCollateral;

    /**
     * @notice InvoiceNFT contract
     * @dev The InvoiceNFT contract is used to create and manage invoices
     */
    InvoiceNFT public immutable invoiceNFT;

    /**
     * @notice Collateral contract
     * @dev The Collateral contract is used to manage collateral
     */
    Collateral public immutable collateral;

    /**
     * @notice PrimaToken contract
     * @dev The PrimaToken contract is used to manage the Prima token
     */
    PrimaToken public immutable primaToken;

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
     * @notice Error for invalid sender
     * @param sender The address of the sender
     */
    error Prima_InvalidSender(address sender);

    /**
     * @notice Error for invalid collateral amount
     * @param collateralAmount The amount of collateral
     * @param activeCollateral The active collateral of the debtor
     * @param totalCollateral The total collateral of the debtor
     */
    error Prima_InvalidCollateralAmount(uint256 collateralAmount, uint256 activeCollateral, uint256 totalCollateral);

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
        require(primaToken.transferFrom(msg.sender, address(collateral), collateralAmount));
        collateral.deposit(msg.sender, collateralAmount);
    }

    /**
     * @notice Compute the minimum and maximum amounts for an invoice
     * @dev This function computes the minimum and maximum amounts for an invoice based on the debtor's credit score
     * @dev This function is useful before creating an invoice
     * @dev This function is for the POC purpose ONLY, those data simulate the real data from an oracle for example
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
            minimumAmount = amount.mulDiv(95, 100);
            maximumAmount = amount;
        } else if (debtorCreditScore == InvoiceNFT.CreditScore.B) {
            minimumAmount = amount.mulDiv(90, 100);
            maximumAmount = amount.mulDiv(95, 100);
        } else if (debtorCreditScore == InvoiceNFT.CreditScore.C) {
            minimumAmount = amount.mulDiv(85, 100);
            maximumAmount = amount.mulDiv(90, 100);
        } else if (debtorCreditScore == InvoiceNFT.CreditScore.D) {
            minimumAmount = amount.mulDiv(80, 100);
            maximumAmount = amount.mulDiv(85, 100);
        } else if (debtorCreditScore == InvoiceNFT.CreditScore.E) {
            minimumAmount = amount.mulDiv(75, 100);
            maximumAmount = amount.mulDiv(80, 100);
        } else {
            minimumAmount = amount.mulDiv(70, 100);
            maximumAmount = amount.mulDiv(75, 100);
        }
    }

    /**
     * @notice Generate an invoice
     * @dev This function generates an invoice using the InvoiceNFT contract
     * @param invoiceParams The parameters of the invoice
     * @return tokenId The token id of the invoice
     */
    function generateInvoice(InvoiceNFT.InvoiceParams calldata invoiceParams) external returns (uint256) {
        require(bytes(invoiceParams.id).length > 0, Prima_InvalidInvoiceId());
        require(invoiceParams.dueDate > block.timestamp, Prima_InvalidDueDate(invoiceParams.dueDate));
        require(
            invoiceParams.amount >= invoiceParams.amountToPay,
            Prima_InvalidInvoiceAmount(invoiceParams.amount, invoiceParams.amountToPay)
        );
        require(invoiceParams.debtor.name != address(0), Prima_InvalidZeroAddress());
        require(invoiceParams.creditor.name == msg.sender, Prima_InvalidSender(msg.sender));
        (uint256 minimumAmount, uint256 maximumAmount) =
            computeAmounts(invoiceParams.amount, invoiceParams.debtor.creditScore);
        require(
            invoiceParams.amountToPay > 0 && invoiceParams.amountToPay >= minimumAmount
                && invoiceParams.amountToPay <= maximumAmount,
            Prima_InvalidInvoiceAmountToPay(invoiceParams.amountToPay, minimumAmount, maximumAmount)
        );

        uint256 tokenId = invoiceNFT.createInvoice(invoiceParams.creditor.name, invoiceParams);
        _debtorInvoices[invoiceParams.debtor.name].push(tokenId);
        _creditorInvoices[invoiceParams.creditor.name].push(tokenId);
        return tokenId;
    }

    /**
     * @notice Accept an invoice
     * @dev This function allows the debtor to accept an invoice
     * @dev This function uses the Collateral contract to manage the collateral
     * @dev This function updates the active collateral of the debtor
     * @param tokenId The token id of the invoice
     * @param collateralAmount The amount of collateral to add
     */
    function acceptInvoice(uint256 tokenId, uint256 collateralAmount) external {
        InvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(tokenId);
        require(invoice.debtor.name == msg.sender, Prima_InvalidSender(msg.sender));

        uint256 totalCollateral = collateral.getCollateral(msg.sender);
        require(
            _activeCollateral[msg.sender] + collateralAmount <= totalCollateral,
            Prima_InvalidCollateralAmount(collateralAmount, _activeCollateral[msg.sender], totalCollateral)
        );
        _activeCollateral[msg.sender] += collateralAmount;
        invoiceNFT.acceptInvoice(tokenId, collateralAmount);
    }

    /**
     * @notice Invest in an invoice
     * @dev This function allows the investor to invest in an invoice
     * @dev This function transfers the amount to pay from the investor to the creditor
     * @param tokenId The token id of the invoice
     * @param investor The investor of the invoice
     */
    function investInvoice(uint256 tokenId, InvoiceNFT.Company memory investor) external {
        InvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(tokenId);
        require(investor.name == msg.sender, Prima_InvalidSender(msg.sender));
        _investorInvoices[msg.sender].push(tokenId);
        require(primaToken.transferFrom(msg.sender, address(invoice.creditor.name), invoice.amountToPay));
        invoiceNFT.investInvoice(tokenId, investor);
    }

    /**
     * @notice Pay an invoice
     * @dev This function allows the debtor to pay an invoice
     * @dev This function uses the Collateral contract to manage the collateral
     * @dev If the user has enough balance, the invoice is paid. Otherwise, the collateral is used to pay the invoice
     * @param tokenId The token id of the invoice
     */
    function payInvoice(uint256 tokenId) external {
        InvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(tokenId);
        require(invoice.debtor.name == msg.sender, Prima_InvalidSender(msg.sender));
        _activeCollateral[msg.sender] -= invoice.collateral;
        if (primaToken.balanceOf(msg.sender) < invoice.amount) {
            collateral.withdraw(msg.sender, address(invoice.investor.name), invoice.collateral);
            invoiceNFT.payInvoice(tokenId, false);
        } else {
            require(primaToken.transferFrom(msg.sender, address(invoice.investor.name), invoice.amount));
            invoiceNFT.payInvoice(tokenId, true);
        }
    }

    /**
     * @notice Get an invoice
     * @dev This function allows the user to get an invoice
     * @param tokenId The token id of the invoice
     * @return invoice The invoice
     */
    function getInvoice(uint256 tokenId) external view returns (InvoiceNFT.Invoice memory) {
        return invoiceNFT.getInvoice(tokenId);
    }

    /**
     * @notice Get the invoices of the debtor
     * @dev This function allows the user to get the invoices of the debtor
     * @return invoiceIds The invoices IDs as the debtor
     */
    function getDebtorInvoices() external view returns (uint256[] memory invoiceIds) {
        return _debtorInvoices[msg.sender];
    }

    /**
     * @notice Get the invoices of the creditor
     * @dev This function allows the user to get the invoices of the creditor
     * @return invoiceIds The invoices IDs as the creditor
     */
    function getCreditorInvoices() external view returns (uint256[] memory invoiceIds) {
        return _creditorInvoices[msg.sender];
    }

    /**
     * @notice Get the invoices of the investor
     * @dev This function allows the user to get the invoices of the investor
     * @return invoiceIds The invoices IDs as the investor
     */
    function getInvestorInvoices() external view returns (uint256[] memory invoiceIds) {
        return _investorInvoices[msg.sender];
    }
}
