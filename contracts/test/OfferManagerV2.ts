import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { sampleWitness } from "./Verifier";

const REGISTER_FUNC_V2 =
  "register(bytes32,uint256,uint256,address,bytes32,address,uint256,bytes)";

describe("OfferManagerV2", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOfferManager() {
    // Contracts are deployed using the first signer/account by default
    const [owner, maker, taker] = await ethers.getSigners();

    const networkIndex =
      "0x00000000000000000000000000000000000000000000000010d1cb00b658931e";

    const Verifier = await ethers.getContractFactory("VerifierTest");
    const verifier = await Verifier.deploy(networkIndex);

    const OfferManager = await ethers.getContractFactory("OfferManagerV2Test");
    const offerManager = await OfferManager.deploy();
    await offerManager.changeVerifier(verifier.address);

    return { verifier, offerManager, owner, maker, taker };
  }

  const sampleOffer = {
    makerIntmaxAddress:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    makerAssetId:
      "0x000000000000000000000000000000000000000000000000f7c23e5c2d79b6ae",
    makerAmount: 3,
    takerIntmaxAddress:
      "0x0000000000000000000000000000000000000000000000000000000000000002",
    takerTokenAddress: "0x0000000000000000000000000000000000000000", // ETH
    takerAmount: ethers.utils.parseEther("0.0001"),
  };

  describe("Deployment", function () {
    it("Should return the valid next offer ID", async function () {
      const { offerManager } = await loadFixture(deployOfferManager);

      expect(await offerManager.nextOfferId()).to.equal(0);
    });
  });

  describe("Register", function () {
    it("Should execute without errors", async function () {
      const { verifier, offerManager, maker, taker } = await loadFixture(
        deployOfferManager
      );

      const {
        diffTreeInclusionProof,
        blockHeader,
        blockHash,
        nonce,
        recipientMerkleSiblings,
      } = sampleWitness;

      const witness = await verifier.calcWitness(
        blockHash,
        nonce,
        recipientMerkleSiblings,
        diffTreeInclusionProof,
        blockHeader
      );

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
        takerTokenAddress,
        takerAmount,
      } = sampleOffer;
      const offerId = 0;

      await expect(
        offerManager
          .connect(maker)
          [REGISTER_FUNC_V2](
            makerIntmaxAddress,
            makerAssetId,
            makerAmount,
            taker.address,
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            witness
          )
      )
        .to.emit(offerManager, "OfferTakerUpdated")
        .withArgs(offerId, takerIntmaxAddress);
    });
  });

  describe("Update taker", function () {
    it("Should execute without errors", async function () {
      const { offerManager, maker, taker } = await loadFixture(
        deployOfferManager
      );

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
        takerTokenAddress,
        takerAmount,
      } = sampleOffer;

      await offerManager
        .connect(maker)
        .testRegister(
          makerIntmaxAddress,
          makerAssetId,
          makerAmount,
          taker.address,
          takerIntmaxAddress,
          takerTokenAddress,
          takerAmount
        );

      const offerId = 0;
      const newTakerIntmaxAddress =
        "0x0000000000000000000000000000000000000000000000000000000000000003";

      await expect(
        offerManager.connect(maker).updateTaker(offerId, newTakerIntmaxAddress)
      )
        .to.emit(offerManager, "OfferTakerUpdated")
        .withArgs(offerId, newTakerIntmaxAddress);
    });
  });

  describe("Activate", function () {
    it("Should execute without errors", async function () {
      const { offerManager, maker, taker } = await loadFixture(
        deployOfferManager
      );

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
        takerTokenAddress,
        takerAmount,
      } = sampleOffer;

      await offerManager
        .connect(maker)
        .testRegister(
          makerIntmaxAddress,
          makerAssetId,
          makerAmount,
          taker.address,
          takerIntmaxAddress,
          takerTokenAddress,
          takerAmount
        );

      const offerId = 0;

      await expect(
        offerManager.connect(taker).activate(offerId, { value: takerAmount })
      )
        .to.emit(offerManager, "OfferActivated")
        .withArgs(offerId, takerIntmaxAddress);
    });
  });

  describe("Upgrade", function () {
    it("Should execute without errors", async function () {
      const [, maker, taker] = await ethers.getSigners();

      const OfferManager = await ethers.getContractFactory("OfferManager");
      const offerManager = await upgrades.deployProxy(OfferManager);

      const offerManagerProxyAddress = offerManager.address;

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
        takerTokenAddress,
        takerAmount,
      } = sampleOffer;

      await offerManager
        .connect(maker)
        .register(
          makerIntmaxAddress,
          makerAssetId,
          makerAmount,
          taker.address,
          takerIntmaxAddress,
          takerTokenAddress,
          takerAmount
        );

      const offerId = 0;

      const OfferManagerV2 = await ethers.getContractFactory("OfferManagerV2");
      const offerManagerV2 = await upgrades.upgradeProxy(
        offerManagerProxyAddress,
        OfferManagerV2
      );

      await expect(
        offerManagerV2.connect(taker).activate(offerId, { value: takerAmount })
      )
        .to.emit(offerManagerV2, "OfferActivated")
        .withArgs(offerId, takerIntmaxAddress);

      const offer = await offerManagerV2.getOffer(offerId);
      expect(offer.maker).to.be.equal(maker.address);
      expect(offer.makerIntmaxAddress).to.be.equal(makerIntmaxAddress);
      expect(offer.makerAssetId).to.be.equal(makerAssetId);
      expect(offer.makerAmount).to.be.equal(makerAmount.toString());
      expect(offer.taker).to.be.equal(taker.address);
      expect(offer.takerIntmaxAddress).to.be.equal(takerIntmaxAddress);
      expect(offer.takerTokenAddress).to.be.equal(takerTokenAddress);
      expect(offer.takerAmount).to.be.equal(takerAmount.toString());
      expect(offer.activated).to.be.equal(true);
    });
  });
});
