// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./WhitelistedUsers.sol";

contract NFTPresale is ERC721URIStorage, WhitelistedUsers {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    //IERC721 NftToken ;
    IERC721 private PERC721;

    address NftAddr;
    uint256 rate;
    bool PreSaleM;
    bool PublicM;
    uint256 weiRaised;
    uint256 mintAmount;

    uint256 start;
    uint256 _days;
    uint256 tokenId;

    constructor(address _nftAddr, uint256 _rate) ERC721("Pace", "PC") {
        require(_nftAddr != address(0));
        rate = _rate;
        // NftToken = IERC721(_nftAddr);
        PERC721 = IERC721(_nftAddr);
    }

    event BoughtTokens(address indexed to, uint256 _amount, string _tokenURIs);

    function togglePresale() public onlyOwner {
        PreSaleM = !PreSaleM;
    }

    function togglePublicSale() public onlyOwner {
        PublicM = !PublicM;
    }

    function startNFTPresale(uint256 _start, uint256 _ddays) public onlyOwner {
        start = _start;
        _days = _ddays;
    }

    function isActive() public view returns (bool) {
        return (block.timestamp >= start && block.timestamp <= start + (_days * 1 days));
    }

    function setMintAmount(uint256 _mintAmount) public returns (uint256) {
        mintAmount = _mintAmount;
        return mintAmount;
    }

    modifier checkNftAmount(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= 10);
        _;
    }

    function buyNFt(
        address to,
        uint256 _mintAmount,
        string memory uri
    ) external payable checkNftAmount(_mintAmount) {
        require(PublicM, "sale is OFF");
        require(msg.value >= _mintAmount * rate);

        for (uint256 i = 0; i < _mintAmount; i++) {
            tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            // uint256 tokenId= _tokenIdCounter.increment();
            // tokenId = _tokenIdCounter.current();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);

            weiRaised = weiRaised + msg.value;
            safeTransferFrom(address(this), msg.sender, tokenId);
        }
        emit BoughtTokens(msg.sender, _mintAmount, uri);
    }

    function buyNFTPresale(
        bytes32[] calldata _proof,
        string memory uri,
        address to,
        uint256 _mintAmount
    ) external payable isWhitelisted(_proof) checkNftAmount(_mintAmount) {
        require(PreSaleM, "Presale is OFF");
        require(msg.value >= _mintAmount * rate);

        for (uint256 i = 0; i < _mintAmount; i++) {
            tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);

            safeTransferFrom(address(this), msg.sender, tokenId);
        }
        emit BoughtTokens(msg.sender, _mintAmount, uri);
    }

    function withdrawETH(address admin) external onlyOwner {
        payable(admin).transfer(address(this).balance);
    }

    function withdrawNFT(uint256 _tokenId) public onlyOwner {
        safeTransferFrom(address(this), msg.sender, _tokenId);
    }
}
