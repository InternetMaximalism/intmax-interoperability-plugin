import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {
  assetStructType,
  blockHeaderStructType,
  merkleProofStructType,
  sampleWitness,
} from "./sampleData";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

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

    const OfferManager = await ethers.getContractFactory("OfferManagerV3Test");
    const offerManager = await OfferManager.deploy();
    await offerManager.changeVerifier(verifier.address);

    const Erc20 = await ethers.getContractFactory("ERC20Test");
    const testToken = await Erc20.deploy();

    return { verifier, offerManager, testToken, owner, maker, taker };
  }

  const zeroAddress = "0x0000000000000000000000000000000000000000";

  const sampleOffer = {
    makerIntmaxAddress:
      "0x0000000000000000000000000000000000000000000000000000000000000000",
    makerAssetId: sampleWitness.tokenAddress,
    makerAmount: sampleWitness.tokenAmount,
    takerIntmaxAddress: sampleWitness.recipient,
    takerAmount: ethers.utils.parseEther("0.0001"),
  };

  const calcWitness = async (owner: SignerWithAddress) => {
    const { diffTreeInclusionProof, blockHeader, recipient } = sampleWitness;

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
      const { offerManager } = await loadFixture(deployOfferManager);

      expect(await offerManager.nextOfferId()).to.equal(0);
    });
  });

  describe("Register with ETH", function () {
    it("Should execute without errors", async function () {
      const { offerManager, owner, maker, taker } = await loadFixture(
        deployOfferManager
      );

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
        takerAmount,
      } = sampleOffer;

      const takerTokenAddress = zeroAddress; // ETH

      const witness = calcWitness(owner);

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
        takerAmount,
      } = sampleOffer;

      const takerTokenAddress = zeroAddress; // ETH

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
        takerAmount,
      } = sampleOffer;

      const takerTokenAddress = zeroAddress; // ETH

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

  describe("Register with ERC20", function () {
    it("Should fail with errors", async function () {
      const { offerManager, testToken, owner, maker, taker } =
        await loadFixture(deployOfferManager);

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
        takerAmount,
      } = sampleOffer;

      const takerTokenAddress = testToken.address;
      console.log("takerTokenAddress:", takerTokenAddress);

      const witness = calcWitness(owner);

      expect(await offerManager.tokenAllowList(takerTokenAddress)).to.be.equal(
        false
      );

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
      ).to.be.revertedWith(
        "the taker's token address is neither ETH nor ERC20"
      );

      const offerId = 0;

      // Add token address to allow list.
      await expect(
        offerManager
          .connect(owner)
          .addTokenAddressToAllowList([takerTokenAddress])
      )
        .to.emit(offerManager, "TokenAllowListUpdated")
        .withArgs(takerTokenAddress, true);

      // Check that the token address is in the allow list.
      expect(await offerManager.tokenAllowList(takerTokenAddress)).to.be.equal(
        true
      );

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

      // Remove token address from allow list.
      await expect(
        offerManager
          .connect(owner)
          .removeTokenAddressFromAllowList([takerTokenAddress])
      )
        .to.emit(offerManager, "TokenAllowListUpdated")
        .withArgs(takerTokenAddress, false);

      // Check that the token address is not in the allow list.
      expect(await offerManager.tokenAllowList(takerTokenAddress)).to.be.equal(
        false
      );

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
      ).to.be.revertedWith(
        "the taker's token address is neither ETH nor ERC20"
      );
    });
  });

  describe("Activate with ERC20", function () {
    it("Should execute without errors", async function () {
      const { offerManager, testToken, owner, maker, taker } =
        await loadFixture(deployOfferManager);

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
        takerAmount,
      } = sampleOffer;

      const takerTokenAddress = testToken.address;

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

      await testToken.connect(owner).transfer(taker.address, takerAmount);
      await testToken.connect(taker).approve(offerManager.address, takerAmount);
      {
        const tx = offerManager.connect(taker).activate(offerId);
        await expect(tx)
          .to.emit(offerManager, "OfferActivated")
          .withArgs(offerId, takerIntmaxAddress);
        await expect(tx).to.changeTokenBalance(
          testToken,
          taker,
          takerAmount.mul(-1)
        );
      }
    });
  });

  describe("Upgrade", function () {
    it("Should execute without errors", async function () {
      const [owner, maker, taker] = await ethers.getSigners();

      const Erc20 = await ethers.getContractFactory("ERC20Test");
      const testToken = await Erc20.deploy();

      const OfferManager = await ethers.getContractFactory("OfferManager");
      const offerManager = await upgrades.deployProxy(OfferManager);

      const offerManagerProxyAddress = offerManager.address;

      const {
        makerIntmaxAddress,
        makerAssetId,
        makerAmount,
        takerIntmaxAddress,
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
          zeroAddress,
          takerAmount
        );

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
      await offerManagerV2.connect(owner).changeVerifier(verifier.address);

      await expect(
        offerManagerV2.connect(taker).activate(0, { value: takerAmount })
      )
        .to.emit(offerManagerV2, "OfferActivated")
        .withArgs(0, takerIntmaxAddress);

      {
        const offer = await offerManagerV2.offers(0);
        expect(offer.maker).to.be.equal(maker.address);
        expect(offer.makerIntmaxAddress).to.be.equal(makerIntmaxAddress);
        expect(offer.makerAssetId).to.be.equal(makerAssetId);
        expect(offer.makerAmount).to.be.equal(makerAmount.toString());
        expect(offer.taker).to.be.equal(taker.address);
        expect(offer.takerIntmaxAddress).to.be.equal(takerIntmaxAddress);
        expect(offer.takerTokenAddress).to.be.equal(zeroAddress);
        expect(offer.takerAmount).to.be.equal(takerAmount.toString());
        expect(offer.isActivated).to.be.equal(true); // activated -> isActivated
      }

      const witness = calcWitness(owner);

      await expect(
        offerManagerV2
          .connect(maker)
          [REGISTER_FUNC_V2](
            makerIntmaxAddress,
            makerAssetId,
            makerAmount,
            taker.address,
            takerIntmaxAddress,
            testToken.address,
            takerAmount,
            witness
          )
      )
        .to.emit(offerManagerV2, "OfferTakerUpdated")
        .withArgs(1, takerIntmaxAddress);

      const OfferManagerV3 = await ethers.getContractFactory("OfferManagerV3");
      const offerManagerV3 = await upgrades.upgradeProxy(
        offerManagerProxyAddress,
        OfferManagerV3
      );

      await testToken.connect(owner).transfer(taker.address, takerAmount);
      await testToken.connect(taker).approve(offerManager.address, takerAmount);
      await expect(offerManagerV3.connect(taker).activate(1))
        .to.emit(offerManagerV3, "OfferActivated")
        .withArgs(1, takerIntmaxAddress);

      {
        const offer = await offerManagerV3.offers(1);
        expect(offer.maker).to.be.equal(maker.address);
        expect(offer.makerIntmaxAddress).to.be.equal(makerIntmaxAddress);
        expect(offer.makerAssetId).to.be.equal(makerAssetId);

        expect(offer.makerAmount).to.be.equal(makerAmount.toString());
        expect(offer.taker).to.be.equal(taker.address);
        expect(offer.takerIntmaxAddress).to.be.equal(takerIntmaxAddress);
        expect(offer.takerTokenAddress).to.be.equal(testToken.address);
        expect(offer.takerAmount).to.be.equal(takerAmount.toString());
        expect(offer.isActivated).to.be.equal(true);
      }
    });
  });
});
