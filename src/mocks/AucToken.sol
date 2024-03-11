//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AucToken is ERC721Enumerable, Ownable {
    constructor() ERC721("AuctionToken", "AT") Ownable(msg.sender) {}

    function mint(uint256 tokenId) public {
        _mint(msg.sender, tokenId);
    }
}
