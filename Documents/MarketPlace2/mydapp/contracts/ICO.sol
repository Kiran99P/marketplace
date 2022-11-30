// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./WhitelistedUsers.sol";
import "hardhat/console.sol";

contract ICO is WhitelistedUsers {
    IERC20 public token; // The token sold through the ICO
    uint256 public weiRaised; // fund raised
    bool PreSaleM;
    bool PublicM;
    uint256 token_allowed;
    uint256 public initialTokens; // Initial number of tokens available

    uint256 public rate;
    uint256 public cap;
    uint256 public start;
    uint256 public _days;

    constructor(address _tokenAddr, uint256 _initialTokens) {
        require(_tokenAddr != address(0));
        require(_initialTokens > 0);
        initialTokens = _initialTokens * 10**18;
        token = IERC20(_tokenAddr);
    }

    // Event declaration
    event TokenPurchase(address indexed purchaser, uint256 amount);

    function startTokenSale(
        uint256 _rate,
        uint256 _cap,
        uint256 _start,
        uint256 _ddays
    ) external onlyOwner {
        rate = _rate;
        cap = _cap;
        start = _start;
        _days = _ddays;
    }

    function togglePresale() public onlyOwner {
        PreSaleM = !PreSaleM;
    }

    function togglePublicSale() public onlyOwner {
        PublicM = !PublicM;
    }

    function setLimit(uint256 _token_allowed) public onlyOwner {
        token_allowed = _token_allowed;
    }

    function calculateToken(uint256 amount) public view returns (uint256) {
        return (amount / rate) * 10**18;
    }

    function buyTokens() public payable {
        require(msg.value > 0);
        uint256 tokens = calculateToken(msg.value);
        token.transfer(msg.sender, tokens);
        weiRaised += msg.value;

        emit TokenPurchase(msg.sender, tokens);
        payable(owner()).transfer(msg.value);
    }

    function buyTokenPresale(bytes32[] calldata _proof) public payable isWhitelisted(_proof) {
        require(PreSaleM, "Presale is OFF");
        require(msg.value > 0);
        uint256 tokens = calculateToken(msg.value);
        require(tokens < token_allowed, "Only 1000 tokens can be purchased");
        token.transfer(msg.sender, tokens);
        weiRaised += msg.value;

        emit TokenPurchase(msg.sender, tokens);
        payable(owner()).transfer(msg.value);
    }

    fallback() external payable {
        buyTokens();
    }

    receive() external payable {
        buyTokens();
    }

    function withdrawEth(address admin) external onlyOwner {
        payable(admin).transfer(address(this).balance);
    }

    function withdrawToken(address admin) external onlyOwner {
        token.transfer(admin, token.balanceOf(address(this)));
    }
}
