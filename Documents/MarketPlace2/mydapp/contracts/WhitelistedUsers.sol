// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//  WhitelistedCrowdsale
//  Crowdsale in which only whitelisted users can contribute.

contract WhitelistedUsers is Ownable {
    bytes32 public merkleRoot;

    constructor() {}

    // Reverts if investor is not whitelisted. Can be used when extending this contract.

    modifier isWhitelisted(bytes32[] memory _merkleProof) {
        bytes32 sender = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "not whitelisted");
        _;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }
}
