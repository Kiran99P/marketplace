// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaceNFT is Ownable, ERC721URIStorage {
    uint256 public tokenCount;
    IERC721 public nftToken;

    constructor() ERC721("Pace", "PC") {}

    function mint(string memory _tokenURI) external returns (uint256) {
        tokenCount++;
        _safeMint(msg.sender, tokenCount);
        _setTokenURI(tokenCount, _tokenURI);
        return (tokenCount);
    }
}
