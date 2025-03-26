// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {InvoiceNFT} from "./InvoiceNFT.sol";

abstract contract Prima {
    mapping(address => uint256[]) private debtorInvoices;
    mapping(address => uint256[]) private creditorInvoices;
    mapping(address => uint256[]) private investorInvoices;

    function addCollateral(uint256 collateralAmount) external virtual;

    function generateInvoice(InvoiceNFT.Invoice calldata invoice) external virtual returns (uint256);

    function acceptInvoice(uint256 tokenId, uint256 collateralAmount) external virtual;

    function invest(uint256 tokenId) external virtual;

    function pay(uint256 tokenId) external virtual;

    function computeAmount(InvoiceNFT.Invoice calldata invoice) external view virtual returns (uint256);
}
