// SPDX-License-Identifier: MIT
// Create a ERC721 OK
// Anyone can mint OK
// Stake on a smart contract OK
// only people on the whitelist can stake OK
// Owner can stop the staking 
// Owner can freeze the pool (stake or not) 
// Owner can block stake and force unstake OK

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MoonNFT is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(address => uint) whilelist;

    constructor() ERC721("2 THE MOON", "M00N") {
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs::/ipfs_link/";
    }

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
