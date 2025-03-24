// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract InvoiceNFT is ERC721 {
    constructor() ERC721("InvoiceNFT", "INV") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}