import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("OfferManagerReverse", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOfferManager() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const OfferManagerReverse = await ethers.getContractFactory(
      "OfferManagerReverse"
    );
    const offerManagerReverse = await OfferManagerReverse.deploy();

    return { offerManagerReverse, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should return the valid next offer ID", async function () {
      const { offerManagerReverse } = await loadFixture(deployOfferManager);

      expect(await offerManagerReverse.nextOfferId()).to.equal(0);
    });
  });

  describe("Register", function () {
    it("Should register a new offer", async function () {
      const { offerManagerReverse } = await loadFixture(deployOfferManager);

      // Set up the variables for the test.
      const takerIntmaxAddress = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        157, 156, 47, 101, 110, 179, 180, 93,
      ];
      const takerAmount = 1000000000000000;
      const maker = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
      // const makerIntmaxAddress = [
      //   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      //   60, 24, 169, 120, 108, 176, 179, 89,
      // ];
      const makerAssetId = "4330397376401421145";
      const makerAmount = 10;

      // Call the register function on the offer manager contract.
      // Verify that the transaction was successful.
      await expect(
        offerManagerReverse.register(
          takerIntmaxAddress,
          maker,
          makerAssetId,
          makerAmount,
          { value: takerAmount }
        )
      ).not.to.be.reverted;
    });
  });
});
