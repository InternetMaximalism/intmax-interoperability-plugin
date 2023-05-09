import { expect } from "chai";
import { randomBytes } from "crypto";
import { ethers, upgrades } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  assetStructType,
  blockHeaderStructType,
  merkleProofStructType,
  sampleWitness,
  calcSampleWitness,
} from "./sampleData";

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

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
      "OfferManagerReverseV2"
    );
    const offerManagerReverse = await OfferManagerReverse.deploy();
    await offerManagerReverse.initialize();
    await offerManagerReverse.changeVerifier(verifier.address);
    await offerManagerReverse.addTokenAddressToAllowList([ZERO_ADDRESS]);

    const Erc20 = await ethers.getContractFactory("ERC20Test");
    const testToken = await Erc20.deploy();

    return { verifier, offerManagerReverse, testToken, owner, maker, taker };
  }

  // Set up the variables for the test.
  const sampleOffer = {
    makerIntmaxAddress:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    makerAssetId: sampleWitness.tokenAddress,
    makerAmount: sampleWitness.tokenAmount,
    takerIntmaxAddress: sampleWitness.recipient,
    takerAmount: ethers.utils.parseEther("0.0001"),
  };

  // NOTICE: If `txHash` is set, the witness is still valid for SimpleVerifier.
  // However, it's not valid for Verifier.
  const calcWitness = async (owner: SignerWithAddress, txHash?: string) => {
    const { diffTreeInclusionProof, blockHeader, recipient } =
      calcSampleWitness();

    if (txHash) {
      // Set random 32 bytes hex string with 0x-prefix.
      diffTreeInclusionProof.value = txHash;
    }

    const { makerAssetId, makerAmount } = sampleOffer;

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

    return witness;
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

      const { takerIntmaxAddress, takerAmount, makerAssetId, makerAmount } =
        sampleOffer;

      const takerTokenAddress = ZERO_ADDRESS;

      {
        const tx = offerManagerReverse
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
        await expect(tx).to.emit(offerManagerReverse, "OfferRegistered");
        await expect(tx).to.changeEtherBalance(taker, takerAmount.mul(-1));
      }
    });
  });

  describe("Activate with ETH", function () {
    it("Should activate an offer", async function () {
      const { offerManagerReverse, owner, maker, taker } = await loadFixture(
        deployOfferManager
      );

      const { takerIntmaxAddress, takerAmount, makerAssetId, makerAmount } =
        sampleOffer;

      const takerTokenAddress = ZERO_ADDRESS;

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

      const witness = await calcWitness(owner);

      {
        const tx = offerManagerReverse
          .connect(maker)
          .activate(offerId, witness);
        await expect(tx)
          .to.emit(offerManagerReverse, "OfferActivated")
          .withArgs(offerId, maker.address);
        await expect(tx).to.changeEtherBalance(maker, takerAmount);
      }
    });

    it("Should not activate an offer with already used witness", async function () {
      const { offerManagerReverse, owner, maker, taker } = await loadFixture(
        deployOfferManager
      );

      const { takerIntmaxAddress, takerAmount, makerAssetId, makerAmount } =
        sampleOffer;

      const takerTokenAddress = ZERO_ADDRESS;

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

      const witness = await calcWitness(owner);

      offerManagerReverse.connect(maker).activate(0, witness);

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
      expect(
        offerManagerReverse.connect(maker).activate(1, witness)
      ).to.be.revertedWith("Given witness already used");
    });
  });

  describe("Register with ERC20", function () {
    it("Should register a new offer", async function () {
      const { offerManagerReverse, testToken, owner, maker, taker } =
        await loadFixture(deployOfferManager);

      const { takerIntmaxAddress, takerAmount, makerAssetId, makerAmount } =
        sampleOffer;

      const takerTokenAddress = testToken.address;

      await testToken.connect(owner).transfer(taker.address, takerAmount);
      await testToken
        .connect(taker)
        .approve(offerManagerReverse.address, takerAmount);

      expect(
        offerManagerReverse
          .connect(taker)
          .register(
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            maker.address,
            makerAssetId,
            makerAmount
          )
      ).to.be.revertedWith(
        "the taker's token address is not in the token allow list"
      );

      await offerManagerReverse
        .connect(owner)
        .addTokenAddressToAllowList([testToken.address]);

      {
        const tx = offerManagerReverse
          .connect(taker)
          .register(
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            maker.address,
            makerAssetId,
            makerAmount
          );
        await expect(tx).to.emit(offerManagerReverse, "OfferRegistered");
        await expect(tx).to.changeTokenBalance(
          testToken,
          taker,
          takerAmount.mul(-1)
        );
      }

      await offerManagerReverse
        .connect(owner)
        .removeTokenAddressFromAllowList([testToken.address]);

      expect(
        offerManagerReverse
          .connect(taker)
          .register(
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            maker.address,
            makerAssetId,
            makerAmount
          )
      ).to.be.revertedWith(
        "the taker's token address is not in the token allow list"
      );
    });
  });

  describe("Activate with ERC20", function () {
    it("Should activate an offer", async function () {
      const { offerManagerReverse, testToken, owner, maker, taker } =
        await loadFixture(deployOfferManager);

      const { takerIntmaxAddress, takerAmount, makerAssetId, makerAmount } =
        sampleOffer;

      const takerTokenAddress = testToken.address;

      await testToken.connect(owner).transfer(taker.address, takerAmount);
      await testToken
        .connect(taker)
        .approve(offerManagerReverse.address, takerAmount);

      await offerManagerReverse
        .connect(owner)
        .addTokenAddressToAllowList([testToken.address]);

      offerManagerReverse
        .connect(taker)
        .register(
          takerIntmaxAddress,
          takerTokenAddress,
          takerAmount,
          maker.address,
          makerAssetId,
          makerAmount
        );

      const offerId = 0;

      const witness = await calcWitness(owner);

      {
        const tx = offerManagerReverse
          .connect(maker)
          .activate(offerId, witness);
        await expect(tx)
          .to.emit(offerManagerReverse, "OfferActivated")
          .withArgs(offerId, maker.address);
        await expect(tx).to.changeTokenBalance(testToken, maker, takerAmount);
      }
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
        takerAmount,
      } = sampleOffer;

      await offerManagerReverse
        .connect(taker)
        .register(
          takerIntmaxAddress,
          ZERO_ADDRESS,
          takerAmount,
          maker.address,
          makerAssetId,
          makerAmount,
          { value: takerAmount }
        );

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

      {
        const witness = await calcWitness(owner);
        await expect(offerManagerReverseV2.connect(maker).activate(0, witness))
          .to.emit(offerManagerReverseV2, "OfferActivated")
          .withArgs(0, maker.address);
      }

      {
        const offer = await offerManagerReverseV2.offers(0);
        expect(offer.maker).to.be.equal(maker.address);
        expect(offer.makerIntmaxAddress).to.be.equal(makerIntmaxAddress);
        expect(offer.makerAssetId).to.be.equal(makerAssetId);
        expect(offer.makerAmount).to.be.equal(makerAmount.toString());
        expect(offer.taker).to.be.equal(taker.address);
        expect(offer.takerIntmaxAddress).to.be.equal(takerIntmaxAddress);
        expect(offer.takerTokenAddress).to.be.equal(ZERO_ADDRESS);
        expect(offer.takerAmount).to.be.equal(takerAmount.toString());
        expect(offer.isActivated).to.be.equal(true); // NOTICE: activated -> isActivated
      }

      await offerManagerReverseV2
        .connect(owner)
        .addTokenAddressToAllowList([ZERO_ADDRESS]);

      await offerManagerReverseV2
        .connect(taker)
        .register(
          takerIntmaxAddress,
          ZERO_ADDRESS,
          takerAmount,
          maker.address,
          makerAssetId,
          makerAmount,
          { value: takerAmount }
        );

      // const OfferManagerReverseV3 = await ethers.getContractFactory(
      //   "OfferManagerReverseV3"
      // );
      // const offerManagerReverseV3 = await upgrades.upgradeProxy(
      //   offerManagerReverseProxyAddress,
      //   OfferManagerReverseV3
      // );

      // {
      //   const anotherTxHash =
      //     "0x05ada85b5877f42956ac2793e1ae10fb79ec60718130a13a2968c9bbc6b7d59f";
      //   const witness = await calcWitness(owner, anotherTxHash);
      //   await expect(offerManagerReverseV3.connect(maker).activate(1, witness))
      //     .to.emit(offerManagerReverseV3, "OfferActivated")
      //     .withArgs(1, maker.address);
      // }

      // {
      //   const offer = await offerManagerReverseV3.offers(1);
      //   expect(offer.maker).to.be.equal(maker.address);
      //   expect(offer.makerIntmaxAddress).to.be.equal(makerIntmaxAddress);
      //   expect(offer.makerAssetId).to.be.equal(makerAssetId);
      //   expect(offer.makerAmount).to.be.equal(makerAmount.toString());
      //   expect(offer.taker).to.be.equal(taker.address);
      //   expect(offer.takerIntmaxAddress).to.be.equal(takerIntmaxAddress);
      //   expect(offer.takerTokenAddress).to.be.equal(ZERO_ADDRESS);
      //   expect(offer.takerAmount).to.be.equal(takerAmount.toString());
      //   expect(offer.isActivated).to.be.equal(true); // NOTICE: activated -> isActivated
      // }
    });
  });
});
