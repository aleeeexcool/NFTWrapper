// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721, Ownable {
    uint256 public tokenId;

    constructor() ERC721("MyNFT", "MNFT") {}

    function mint(address to) public onlyOwner {
        tokenId++;
        _safeMint(to, tokenId);
    }

    function burn(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        _burn(_tokenId);
    }
}

