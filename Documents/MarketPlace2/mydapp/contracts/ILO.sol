// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/contracts/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract ASTILO is OwnableUpgradeable,PausableUpgradeable,ReentrancyGuardUpgradeable {

//using SafeMath for uint256;
IERC20Upgradeable token;

bytes32 merkleRoot ;

uint256 rate ;
uint256 cap ;
uint256 startSeed;
uint256 endSeed;
uint256 startPrivate;
uint256 endPrivate;
uint256 _days ;
uint256 initialTokens;
uint256 cTokens;           // tokens per day
uint256 Tokens ;
uint256 cliffStart1 ;
uint256 cliffEnd1 ;
uint256 vestingPeriod ; //days
uint256 raisedAmount;

bool public privateSale;
bool public seedSale;

struct investorData{
    uint256 lockTime;
    uint256 purchasedTokens;
    uint256 LastClaim;
    bool IsInvested; 
    bool Isclaimed ;   
}

mapping (address => investorData) public _investorData ;

enum Stage{
    locked,
    seedSale,
    privateSale
}


function initialize(address _tokenAddr ,uint256 _initialTokens) external initializer {
    require(_tokenAddr != address(0));
    require(_initialTokens > 0);

      initialTokens = _initialTokens *10**18;
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    token = IERC20Upgradeable(_tokenAddr);
}

function StartSeedSale(uint256 _rate, uint256 _cap, uint256 _startSeed,
uint256 _endSeed,uint256 _ddays, uint256 _cliffend1 , uint256 _vestingPeriod) 
external whenNotPaused onlyOwner{

        require(seedSale && !privateSale);

        rate = _rate ;
        cap = _cap;
        startSeed = _startSeed;
        endSeed = _endSeed ;
        _days = _ddays * 1 days;
        cliffEnd1 = _cliffend1;
        vestingPeriod = _vestingPeriod * 1 days ;
 }

 function StartPrivateSale(uint256 _rate, uint256 _cap, uint256 _startPrivate,
 uint256 _endPrivate, uint256 _ddays, uint256 _cliffend1 , uint256 _vestingPeriod)
  external whenNotPaused onlyOwner{

       require(!seedSale && privateSale);

        rate = _rate ;
        cap = _cap;
        startPrivate = _startPrivate;
        endPrivate = _endPrivate ;
        _days = _ddays * 1 days;
        cliffEnd1 = _cliffend1;
        vestingPeriod = _vestingPeriod * 1 days ;

 }

 //  initialtokens = 10000; ,cliffend1 =    1669404661  26 1         ; vestingperiod=  10 days  
 //  startsale rate = 0.002 ether(2^10) ; cap = 20 * 10^18 ; start = 1668886261 ; days= 0.0001;
//   0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 
// 20000000000     200000000000000   ;    1669702215 now  1669701015 ce

// start = 1/11/22  1667284200 ; days = 10 , cliffend = 20/11/22 1668925800  ;
// vesting period = 10

function checkStage() public view returns(Stage stage){
    if (block.timestamp < startSeed){
        stage = Stage.locked ;
        return stage;
    }else if (block.timestamp >= startSeed && block.timestamp <= endSeed ){
        stage = Stage.seedSale ;
        return stage;
    }else if (block.timestamp >= startPrivate && block.timestamp <= endPrivate){
        stage = Stage.privateSale ;
        return stage;
    }
}

    modifier buffer() {
           
            require(checkStage() != Stage.locked);
            if(seedSale){
            require(checkStage() == Stage.seedSale);
            }else{
                require(checkStage()== Stage.privateSale);
            }
            _;
        }

function setCliff(uint256 _startCliff , uint256 _endCliff) public {
    cliffStart1 = _startCliff;
    cliffEnd1 = _endCliff;
}

function buyTokens() public payable whenNotPaused nonReentrant buffer  {
    require(msg.value > 0);

   uint256 TimeAtP = block.timestamp;
   uint256 amount = msg.value;
   Tokens = amount/rate;
   
   investorData storage investor = _investorData[_msgSender()];

    investor.lockTime = TimeAtP;
    investor.purchasedTokens = investor.purchasedTokens += Tokens;
    investor.IsInvested = true;
}

modifier checkCliffPeriod() {
    require(block.timestamp >= cliffEnd1, "Cliff Period is not end");
    _;
}



function calculateTokens() internal  returns(uint256) {
    investorData storage investor = _investorData[_msgSender()];
    uint256 TotalTokens = investor.purchasedTokens;
    cTokens = TotalTokens/vestingPeriod;   
    return cTokens; 
}

function claimTokens() external checkCliffPeriod {
    
    address addr = _msgSender();
    uint256 Days_till;
    investorData storage investor = _investorData[_msgSender()];

    if(investor.Isclaimed= true){
            uint256 lastClaimTime = investor.LastClaim;
            Days_till = (block.timestamp - lastClaimTime)/60/60/24 ;
    } else{
             Days_till = (block.timestamp - cliffEnd1)/60/60/24 ;
    }

    uint256 TokensPerDay = calculateTokens();

    uint256 TokensToClaim = Days_till * TokensPerDay;
    require(token.transfer(addr, TokensToClaim));
    investor.LastClaim = block.timestamp;

    investor.Isclaimed = true ;

}

function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot ;
}

function getMerkleRoot() external view returns(bytes32){
    return merkleRoot ;
}
 

function toggleSeedSale() public onlyOwner {
     seedSale = !seedSale;
}


function togglePrivateSale() public onlyOwner {
     privateSale = !privateSale;
}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

function isActive() public view returns (bool) {
    return (
        block.timestamp >= startSeed && // Must be after the start date
        block.timestamp <= endPrivate && // Must be before the end date
        goalReached() == false // Goal must not already be reached
    );
}

function goalReached() public view returns (bool) {
    return (raisedAmount >= cap * 1 ether);
  }

fallback() external payable {
    buyTokens();
}

receive() external payable{
      buyTokens();
}

}
