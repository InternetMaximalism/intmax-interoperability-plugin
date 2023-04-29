import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {
  assetStructType,
  blockHeaderStructType,
  merkleProofStructType,
  sampleWitness,
} from "./sampleData";

describe("OfferManagerReverseV2", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOfferManager() {
    // Contracts are deployed using the first signer/account by default
    const [owner, maker, taker] = await ethers.getSigners();

    const networkIndex =
      "0x0000000000000000000000000000000000000000000000000000000000000002";

    const Verifier = await ethers.getContractFactory("SimpleVerifierTest");
    const verifier = await Verifier.deploy(networkIndex);

    const OfferManagerReverse = await ethers.getContractFactory(
      "OfferManagerReverseV2Test"
    );
    const offerManagerReverse = await OfferManagerReverse.deploy();
    await offerManagerReverse.changeVerifier(verifier.address);

    return { verifier, offerManagerReverse, owner, maker, taker };
  }

  // Set up the variables for the test.
  const sampleOffer = {
    makerIntmaxAddress:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    makerAssetId: sampleWitness.tokenAddress,
    makerAmount: sampleWitness.tokenAmount,
    takerIntmaxAddress: sampleWitness.recipient,
    takerTokenAddress: "0x0000000000000000000000000000000000000000", // ETH
    takerAmount: ethers.utils.parseEther("0.0001"),
  };

  describe("Deployment", function () {
    it("Should return the valid next offer ID", async function () {
      const { offerManagerReverse } = await loadFixture(deployOfferManager);

      expect(await offerManagerReverse.nextOfferId()).to.equal(0);
    });
  });

  describe("Register with ETH", function () {
    it("Should register a new offer", async function () {
      const { offerManagerReverse, maker, taker } = await loadFixture(
        deployOfferManager
      );

      const {
        takerIntmaxAddress,
        takerTokenAddress,
        takerAmount,
        makerAssetId,
        makerAmount,
      } = sampleOffer;

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

  describe("Activate with ETH", function () {
    it("Should activate an offer", async function () {
      const { offerManagerReverse, owner, maker, taker } = await loadFixture(
        deployOfferManager
      );

      const { diffTreeInclusionProof, blockHeader, recipient } = sampleWitness;

      const {
        takerIntmaxAddress,
        takerTokenAddress,
        takerAmount,
        makerAssetId,
        makerAmount,
      } = sampleOffer;

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

      const offerId = 0;

      const asset = {
        tokenAddress: makerAssetId,
        tokenId: 0,
        amount: makerAmount,
      };
      const abiEncoder = new ethers.utils.AbiCoder();
      const message = abiEncoder.encode(
        [
          `${assetStructType}[]`,
          "bytes32",
          merkleProofStructType,
          blockHeaderStructType,
        ],
        [[asset], recipient, diffTreeInclusionProof, blockHeader]
      );

      const messageBytes = Buffer.from(message.slice(2), "hex");
      const signature = await owner.signMessage(messageBytes);

      const witness = abiEncoder.encode(
        [
          `${assetStructType}[]`,
          "bytes32",
          merkleProofStructType,
          blockHeaderStructType,
          "bytes",
        ],
        [[asset], recipient, diffTreeInclusionProof, blockHeader, signature]
      );

      await expect(
        offerManagerReverse.connect(maker).activate(offerId, witness)
      )
        .to.emit(offerManagerReverse, "OfferActivated")
        .withArgs(offerId, maker.address);
    });
  });

  describe("Upgrade", function () {
    it("Should execute without errors", async function () {
      const [owner, maker, taker] = await ethers.getSigners();

      const OfferManagerReverse = await ethers.getContractFactory(
        "OfferManagerReverse"
      );
      const offerManagerReverse = await upgrades.deployProxy(
        OfferManagerReverse
      );

      const offerManagerReverseProxyAddress = offerManagerReverse.address;

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
        takerTokenAddress,
        takerAmount,
      } = sampleOffer;

      await offerManagerReverse
        .connect(taker)
        .register(
          takerIntmaxAddress,
          takerTokenAddress,
          takerAmount,
          maker.address,
          makerAssetId,
          makerAmount,
          { value: takerAmount }
        );

      const offerId = 0;

      const networkIndex =
        "0x0000000000000000000000000000000000000000000000000000000000000002";

      const Verifier = await ethers.getContractFactory("SimpleVerifier");
      const verifier = await upgrades.deployProxy(Verifier, [networkIndex]);

      const OfferManagerReverseV2 = await ethers.getContractFactory(
        "OfferManagerReverseV2"
      );
      const offerManagerReverseV2 = await upgrades.upgradeProxy(
        offerManagerReverseProxyAddress,
        OfferManagerReverseV2
      );
      await offerManagerReverseV2.changeVerifier(verifier.address);

      const { diffTreeInclusionProof, blockHeader, recipient } = sampleWitness;

      const asset = {
        tokenAddress: makerAssetId,
        tokenId: 0,
        amount: makerAmount,
      };
      const abiEncoder = new ethers.utils.AbiCoder();
      const message = abiEncoder.encode(
        [
          `${assetStructType}[]`,
          "bytes32",
          merkleProofStructType,
          blockHeaderStructType,
        ],
        [[asset], recipient, diffTreeInclusionProof, blockHeader]
      );

      const messageBytes = Buffer.from(message.slice(2), "hex");
      const signature = await owner.signMessage(messageBytes);

      const witness = abiEncoder.encode(
        [
          `${assetStructType}[]`,
          "bytes32",
          merkleProofStructType,
          blockHeaderStructType,
          "bytes",
        ],
        [[asset], recipient, diffTreeInclusionProof, blockHeader, signature]
      );

      await expect(
        offerManagerReverseV2.connect(maker).activate(offerId, witness)
      )
        .to.emit(offerManagerReverseV2, "OfferActivated")
        .withArgs(offerId, maker.address);

      const offer = await offerManagerReverseV2.getOffer(offerId);
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
