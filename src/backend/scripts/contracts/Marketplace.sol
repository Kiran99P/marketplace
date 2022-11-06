// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "hardhat/console.sol";



interface INFT721{
    
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns(uint256);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external ;
}

contract NFTMarketplace is Ownable, ReentrancyGuard, ERC721URIStorage {
    using Counters for Counters.Counter; 

    Counters.Counter public tokenId;
    address payable public owner;
    uint public ListingCharge;


    struct MarketItem {     //item details
      uint256 tokenId;   //unique
      address payable seller;
      address payable owner;
      uint256 price;
      bool sold;
    }

    struct tokenDetails721 {

        address seller;
        uint128 price;
        uint32 duration;
        uint128 maxBid;
        address maxBidUser;
        bool isActive;
        uint128[] bidAmounts;
        address[] users;
    }

    struct Offer {

        address[] offerers;
        uint128[] offerAmounts;
        address owner;
        bool isAccepted;
    }


    // tokenId => MarketItem
    mapping(uint256 => MarketItem) private idToMarketItem;  // storing multiple MarketItem

    // nft => tokenId =>  struct tokenDetails721
    mapping(address => mapping(uint256 => tokenDetails721)) public auctionNfts;

     // nft => tokenId => offer struct
    mapping(address => mapping(uint256 => Offer)) public offerNfts;
    
    INFT721 private PERC721;   

    IERC20 private PERC20;

    
    constructor(address _erc721, address _erc20) {
    
        PERC721 = INFT721(_erc721);
        PERC20 = IERC20(_erc20);
        owner = payable(msg.sender);

    }
        

    event MarketItemCreated (
      uint256 indexed tokenId,
      address seller,
      address owner,
      uint256 price,
      bool sold
    );
    // for users to check the listing charges of the marketplace

     function getListingCharge() public view returns (uint256) {
      return ListingCharge;
    }

     // when marketplace owner wants to update listing charges 
    function updateListingCharges(uint _listingCharge) public payable {
      require(owner == msg.sender, "Only marketplace owner can update listing price.");
      ListingCharge = _listingCharge;
    }

    // List user's existing NFT 

    function listYourNFT721(                        
      uint256 _tokenId,
      address _nft,
      uint128 price
    ) public payable nonReentrant {
    
         IERC721 nft = IERC721(_nft);
      require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
      require(price > 0, "Price must be at least 1 wei");
      require(msg.value == ListingCharge, "Price must be equal to listing Charges");

      idToMarketItem[tokenId] =  MarketItem(
        tokenId,
        payable(msg.sender),
        payable(address(this)),
        price,
        false
      );

      // sending NFT from user's wallet address to Marketplace's contract address

      _transfer(msg.sender, address(this), tokenId);  

      emit MarketItemCreated(
        tokenId,
        msg.sender,
        address(this),
        price,
        false
      );
    }


    // in case user wants to create NFT using Marketplace's minting function, here 
    // user will require to tokenURI and the price he wants to set for it 

     function createToken721(string memory tokenURI, uint256 price) public payable returns (uint) {
        
        tokenId.increment();
        uint256 newTokenId = tokenId.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        listYourNFT721(newTokenId, price);
        return newTokenId;
    }

    function createTokenAuction721(
            address _nft,
            uint256 _tokenId,
            uint128 _price,  // In wei and in token
            uint32 _duration
        ) external {

        require(msg.sender == IERC721(_nft).ownerOf(_tokenId), "Not the owner of tokenId");
        require(_price > 0, "Price should be more than 0");
        require(_duration > block.timestamp, "Invalid duration value");

        auctionNfts[_nft][_tokenId] = tokenDetails721({

            seller : msg.sender,
            price : uint128(_price),
            duration:_duration,
            maxBid: 0,
            maxBidUser: address(0),
            isActive : true,
            bidAmounts: new uint128[](0),
            users: new address[](0)
        });
        // nft => tokenId => tokenDetails721
    // mapping(address => mapping(uint256 => tokenDetails721)) public auctionNfts;
    // struct tokenDetails721 {

        // address seller;
        // uint128 price;
        // uint32 duration;
        // uint128 maxBid;
        // address maxBidUser;
        // bool isActive;
        // uint128[] bidAmounts;
        // address[] users;
    }
    }

   function makeOffer(address _nft, uint256 _tokenId, uint128 _offer) {

    require(PERC20.allowance(msg.sender, address(this)) >= _offer, "token not approved");

    // struct Offer {

    //     address[] offerers;
    //     uint128[] offerAmounts;
    //     address owner;
    //     bool isAccepted;
    // }

    // nft => tokenId => offer struct
    // mapping(address => mapping(uint256 => Offer)) public offerForNfts;

    Offer storage offer = offerForNfts[_nft][_tokenId]; // struct offer

        offer.offerers.push(msg.sender);
        offer.offerAmounts.push(_offer);

  }


  function acceptOffer(address _nft, uint256 _tokenId, address _offerer)  nonReentrant {

        require(IERC721(_nft).ownerOf(_tokenId) == msg.sender, "Only the owner is allowed to accept offer");
        
        Offer memory offer = offerForNfts[_nft][_tokenId];   //struct

        require(!offer.isAccepted, "Already completed");
        require(msg.sender == offer.owner, "Caller is not the seller");
        

        uint256 lastIndex = offer.offerers.length - 1;
        uint128 offerAmount;

        for (uint256 i; i <= lastIndex; i++) {

            if(offer.offerers[i] == _offerer) {

                offerAmount = offer.offerAmounts[i];

            }
        }

        require(PERC20.allowance(_offerer, address(this)) >= offerAmount, "token not approved");

        offer.isAccepted = true;

        IERC721(_nft).safeTransferFrom(
            offer.owner,
            _offerer,
            _tokenId
        );
        
    }

    function rejectOffer(address _nft, uint256 _tokenId)  nonReentrant {
        
        Offer memory offer = offerNfts[_nft][_tokenId];

        require(msg.sender == offer.owner, "You can't reject offers to this token");
        require(!offer.isAccepted, "Offer already accepted or rejected");

        delete offerForNfts[_nft][_tokenId];
    }
  
  function bid721(address _nft, uint256 _tokenId, uint128 _amount)  nonReentrant {

        tokenDetails721 storage auction = auctionForNfts[_nft][_tokenId];

        require(_amount >= auction.price, "Bid less than price");
        require(PERC20.allowance(msg.sender, address(this)) >= _amount, "token not approved");
        require(auction.isActive, "auction not active");
        require(auction.duration > block.timestamp, "Deadline already passed");

        if (auction.bidAmounts.length == 0) {

            auction.maxBid = _amount;
            auction.maxBidUser = msg.sender;

        } else {

            uint256 lastIndex = auction.bidAmounts.length - 1;
            require(auction.bidAmounts[lastIndex] < _amount, "Current max bid is higher than your bid");
            auction.maxBid = _amount;
            auction.maxBidUser = msg.sender;

        }

        auction.users.push(msg.sender);
        auction.bidAmounts.push(_amount);
    }
