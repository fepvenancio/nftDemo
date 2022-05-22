// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title MoonNFT a Project to mint and stake (whitelisted) NFTs
/// @author filipeVenancio  
/// @notice this was created for a job interview
/// @dev still under development
contract MoonNFT is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string public collectionName;
    string public collectionSymbol;

    mapping(address => uint) whilelist;

    /// @notice When the contract goes live the constructor will be the 1st to run
    /// It takes 2 fixed values: Name and Symbol 
    constructor() ERC721("2 THE MOON", "M00N") {
        collectionName = name();
        collectionSymbol = symbol();
    }

    /// @notice _baseURI - The URL where the images will be stored
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs::/ipfs_link/";
    }

    /// @notice safeMint - ERC721 function to mint an NFT
    /// @param to the address that will receive the minted token(NFT)
    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
