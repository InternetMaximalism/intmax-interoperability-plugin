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
    it("Should return the valid next flag ID", async function () {
      const { offerManagerReverse } = await loadFixture(deployOfferManager);

      expect(await offerManagerReverse.nextOfferId()).to.equal(0);
    });
  });

  describe("Lock", function () {
    it("Should lock", async function () {
      const { offerManagerReverse } = await loadFixture(deployOfferManager);

      await expect(
        offerManagerReverse.lock(
          [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 157, 156, 47, 101, 110, 179, 180, 93,
          ],
          "0x0000000000000000000000000000000000000000",
          [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 60, 24, 169, 120, 108, 176, 179, 89,
          ],
          "4330397376401421145",
          10,
          { value: 1000000000000000 }
        )
      ).not.to.be.reverted;
    });
  });
});
