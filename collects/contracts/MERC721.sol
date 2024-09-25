// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MERC721 is ERC721 { 
    constructor() ERC721("MERC721", "MNFT") {}

    // Function to deposit ETH and mint WETH
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    // Function to withdraw ETH by burning WETH
    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) >= msg.sender, "msg.sender is not ownerOf tokenId");
        _burn(tokenId);
    }
}
