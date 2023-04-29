import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {
  assetStructType,
  blockHeaderStructType,
  merkleProofStructType,
  sampleWitness,
} from "./sampleData";

const REGISTER_FUNC_V2 =
  "register(bytes32,uint256,uint256,address,bytes32,address,uint256,bytes)";

describe("OfferManagerV2", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOfferManager() {
    // Contracts are deployed using the first signer/account by default
    const [owner, maker, taker] = await ethers.getSigners();

    const { recipient } = sampleWitness;
    const networkIndex = recipient;

    const Verifier = await ethers.getContractFactory("SimpleVerifierTest");
    const verifier = await Verifier.deploy(networkIndex);

    const OfferManager = await ethers.getContractFactory("OfferManagerV2Test");
    const offerManager = await OfferManager.deploy();
    await offerManager.changeVerifier(verifier.address);

    return { verifier, offerManager, owner, maker, taker };
  }

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
      const { offerManager } = await loadFixture(deployOfferManager);

      expect(await offerManager.nextOfferId()).to.equal(0);
    });
  });

  describe("Register with ETH", function () {
    it("Should execute without errors", async function () {
      const { offerManager, owner, maker, taker } = await loadFixture(
        deployOfferManager
      );

      const { diffTreeInclusionProof, blockHeader, recipient } = sampleWitness;

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
        takerTokenAddress,
        takerAmount,
      } = sampleOffer;

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

  describe("Activate with ETH", function () {
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
      const [owner, maker, taker] = await ethers.getSigners();

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

      const { recipient } = sampleWitness;
      const networkIndex = recipient;

      const Verifier = await ethers.getContractFactory("SimpleVerifier");
      const verifier = await upgrades.deployProxy(Verifier, [networkIndex]);

      const OfferManagerV2 = await ethers.getContractFactory("OfferManagerV2");
      const offerManagerV2 = await upgrades.upgradeProxy(
        offerManagerProxyAddress,
        OfferManagerV2,
        {
          call: {
            fn: "initializeV2",
            args: [owner.address],
          },
        }
      );
      console.log("start changeVerifier()");
      await offerManagerV2.connect(owner).changeVerifier(verifier.address);
      console.log("end changeVerifier()");

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
