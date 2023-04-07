import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("OfferManagerReverse", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOfferManager() {
    // Contracts are deployed using the first signer/account by default
    const [owner, maker, taker] = await ethers.getSigners();

    const OfferManagerReverse = await ethers.getContractFactory(
      "OfferManagerReverse"
    );
    const offerManagerReverse = await OfferManagerReverse.deploy();
    await offerManagerReverse.initialize();

    return { offerManagerReverse, owner, maker, taker };
  }

  describe("Deployment", function () {
    it("Should return the valid next offer ID", async function () {
      const { offerManagerReverse } = await loadFixture(deployOfferManager);

      expect(await offerManagerReverse.nextOfferId()).to.equal(0);
    });
  });

  describe("Register", function () {
    it("Should register a new offer", async function () {
      const { offerManagerReverse, maker, taker } = await loadFixture(
        deployOfferManager
      );

      // Set up the variables for the test.
      const takerIntmaxAddress = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        17, 74, 242, 125, 0, 177, 194, 211,
      ];
      const takerTokenAddress = "0x0000000000000000000000000000000000000000";
      const takerAmount = 1000000000000000;
      // const makerIntmaxAddress = [
      //   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      //   60, 24, 169, 120, 108, 176, 179, 89,
      // ];
      const makerAssetId = "13114056477907499194";
      const makerAmount = 1;

      // Call the register function on the offer manager contract.
      // Verify that the transaction was successful.
      await expect(
        offerManagerReverse
          .connect(taker)
          .register(
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            maker.address,
            makerAssetId,
            makerAmount,
            { value: takerAmount }
          )
      ).not.to.be.reverted;
    });
  });

  describe("Check witness", function () {
    it("Should activate an offer", async function () {
      const { offerManagerReverse, owner, maker, taker } = await loadFixture(
        deployOfferManager
      );

      // Set up the variables for the test.
      const takerIntmaxAddress = Buffer.from(
        "000000000000000000000000000000000000000000000000dc88d9a25da6c75c",
        "hex"
      );
      const takerTokenAddress = "0x0000000000000000000000000000000000000000";
      const takerAmount = 1000000000000000;
      const makerAssetId = "15891190576555935580";
      const makerAmount = 1;

      // Call the register function on the offer manager contract.
      // Verify that the transaction was successful.
      await expect(
        offerManagerReverse
          .connect(taker)
          .register(
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            maker.address,
            makerAssetId,
            makerAmount,
            { value: takerAmount }
          )
      ).not.to.be.reverted;

      const witness = await owner.signMessage(takerIntmaxAddress);
      const signerAddress = ethers.utils.verifyMessage(
        takerIntmaxAddress,
        witness
      );
      if (owner.address !== signerAddress) {
        throw new Error("fail to recover signer");
      }

      // const witness =
      //   "0x9167b390c16fcded1e50302d869a35ea7d6248db2792af7c7f83ed796e882b797c4d70278cc833582d8dc5df06b49ca58edba26d66e586850044f3aa427aa6851b";
      await expect(offerManagerReverse.connect(maker).checkWitness(0, witness))
        .not.to.be.reverted;
    });
  });
});
