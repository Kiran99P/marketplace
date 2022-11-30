import { expect } from "chai";

//import { ethers } from "hardhat";
//import { Presale_Nft } from "../typechain";

const { ethers } = require("hardhat");

describe("Presale_Nft", function () {
  //  let contract;

  //   beforeEach(async () => {
  //  const Presale_Nft = await ethers.getContractFactory("Presale_Nft");
  //  // let  contract = await Presale_Nft.deploy();
  //  const Presale = Presale_Nft.deploy();
  //  const contract = Presale.deployed();
  //   });

  describe("setMintAmount", () => {
    it("should return 2 when given 2", async function () {
      const Presale_Nft = await ethers.getContractFactory("Presale_Nft");
      // let  contract = await Presale_Nft.deploy();
      const Presale = Presale_Nft.deploy();
      const contract = Presale.deployed();

      //const values = await contract.startNFTPresale(78890, 10);
      const values = await contract.setMintAmount(2);

      expect(values).to.be.not.undefined;
      expect(values).to.be.not.null;
      expect(values.toNumber()).to.equal(2);
    });
  });
});
