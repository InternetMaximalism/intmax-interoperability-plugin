import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import {
  assetStructType,
  blockHeaderStructType,
  merkleProofStructType,
  sampleWitness,
  calcSampleWitness,
} from "./sampleData";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const REGISTER_FUNC =
  "register(bytes32,uint256,uint256,address,bytes32,address,uint256)";

const REGISTER_FUNC_V2 =
  "register(bytes32,uint256,uint256,address,bytes32,address,uint256,bytes)";

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

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

    const OfferManager = await ethers.getContractFactory("OfferManagerV2");
    const offerManager = await OfferManager.deploy();
    await offerManager.initialize();
    await offerManager.changeVerifier(verifier.address);
    await offerManager.addTokenAddressToAllowList([ZERO_ADDRESS]); // Allow ETH

    const Erc20 = await ethers.getContractFactory("ERC20Test");
    const testToken = await Erc20.deploy();

    return { verifier, offerManager, testToken, owner, maker, taker };
  }

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
      const { offerManager } = await loadFixture(deployOfferManager);

      expect(await offerManager.nextOfferId()).to.equal(0);
    });
  });

  describe("initialize", function () {
    it("initialize cannot be executed twice", async function () {
      const OfferManager = await ethers.getContractFactory("OfferManagerV2");
      const offerManager = await OfferManager.deploy();
      await offerManager.initialize();
      await expect(offerManager.initialize()).to.be.revertedWith(
        "Initializable: contract is already initialized"
      );
    });
    it("cannot execute initializeV2 after executing initialize", async function () {
      const OfferManager = await ethers.getContractFactory("OfferManagerV2");
      const offerManager = await OfferManager.deploy();
      await offerManager.initialize();
      const tmp = ethers.Wallet.createRandom();
      await expect(offerManager.initializeV2(tmp.address)).to.be.revertedWith(
        "Initializable: contract is already initialized"
      );
    });
  });

  describe("register", function () {
    it("register is deprecated", async function () {
      const { offerManager } = await loadFixture(deployOfferManager);
      await expect(
        offerManager[REGISTER_FUNC](
          ethers.utils.formatBytes32String(""),
          0,
          0,
          ethers.constants.AddressZero,
          ethers.utils.formatBytes32String(""),
          ethers.constants.AddressZero,
          0
        )
      ).to.be.revertedWith(
        "this function is deprecated: 'witness' argument required"
      );
    });
  });

  describe("changeVerifier", function () {
    it("Only the owner can execute changeVerifier", async function () {
      const { offerManager, maker } = await loadFixture(deployOfferManager);
      await expect(
        offerManager.connect(maker).changeVerifier(maker.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
  describe("checkWitness", function () {
    it("It just returns true.r", async function () {
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

      const takerTokenAddress = ZERO_ADDRESS; // ETH

      const witness = calcWitness(owner);

      const offerId = 0;

      await offerManager
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
        );
      const result = await offerManager.checkWitness(offerId, witness);
      expect(result).to.equal(true);
    });
  });
  describe("addTokenAddressToAllowList", function () {
    it("Only the owner can execute addTokenAddressToAllowList", async function () {
      const { offerManager, maker } = await loadFixture(deployOfferManager);
      await expect(
        offerManager.connect(maker).addTokenAddressToAllowList([])
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
    it("Multiple addresses can be added to the allow list", async function () {
      const { offerManager, maker } = await loadFixture(deployOfferManager);
      const wallet1 = ethers.Wallet.createRandom();
      const wallet2 = ethers.Wallet.createRandom();
      const wallet3 = ethers.Wallet.createRandom();
      await offerManager.addTokenAddressToAllowList([
        wallet1.address,
        wallet2.address,
        wallet3.address,
      ]);
      const result1 = await offerManager.tokenAllowList(wallet1.address);
      const result2 = await offerManager.tokenAllowList(wallet2.address);
      const result3 = await offerManager.tokenAllowList(wallet3.address);
      expect(result1).to.equal(true);
      expect(result2).to.equal(true);
      expect(result3).to.equal(true);
    });
    it("Multiple addresses can be deleted to the allow list", async function () {
      const { offerManager, maker } = await loadFixture(deployOfferManager);
      const wallet1 = ethers.Wallet.createRandom();
      const wallet2 = ethers.Wallet.createRandom();
      const wallet3 = ethers.Wallet.createRandom();
      await offerManager.addTokenAddressToAllowList([
        wallet1.address,
        wallet2.address,
        wallet3.address,
      ]);
      await offerManager.removeTokenAddressFromAllowList([
        wallet2.address,
        wallet3.address,
      ]);
      const result1 = await offerManager.tokenAllowList(wallet1.address);
      const result2 = await offerManager.tokenAllowList(wallet2.address);
      const result3 = await offerManager.tokenAllowList(wallet3.address);
      expect(result1).to.equal(true);
      expect(result2).to.equal(false);
      expect(result3).to.equal(false);
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

      const takerTokenAddress = ZERO_ADDRESS; // ETH

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

    it("Should not register an offer with already used witness", async function () {
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

      const takerTokenAddress = ZERO_ADDRESS; // ETH

      const witness = calcWitness(owner);

      await offerManager
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
        );

      expect(
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
      ).to.be.revertedWith("Given witness already used");
    });
  });

  describe("Update taker", function () {
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

      const takerTokenAddress = ZERO_ADDRESS; // ETH

      const witness = calcWitness(owner);

      await offerManager
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

      const takerTokenAddress = ZERO_ADDRESS; // ETH

      const witness = calcWitness(owner);

      await offerManager
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
        );

      const offerId = 0;

      {
        const tx = offerManager
          .connect(taker)
          .activate(offerId, { value: takerAmount });
        await expect(tx)
          .to.emit(offerManager, "OfferActivated")
          .withArgs(offerId, takerIntmaxAddress);
        await expect(tx).to.changeEtherBalances(
          [maker, taker],
          [takerAmount, takerAmount.mul(-1)]
        );
      }
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
        "the taker's token address is not in the token allow list"
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
        "the taker's token address is not in the token allow list"
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

      // Add token address to allow list.
      await offerManager
        .connect(owner)
        .addTokenAddressToAllowList([takerTokenAddress]);

      const witness = calcWitness(owner);

      await offerManager
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
        );

      const offerId = 0;

      await testToken.connect(owner).transfer(taker.address, takerAmount);
      await testToken.connect(taker).approve(offerManager.address, takerAmount);
      {
        const tx = offerManager.connect(taker).activate(offerId);
        await expect(tx)
          .to.emit(offerManager, "OfferActivated")
          .withArgs(offerId, takerIntmaxAddress);
        await expect(tx).to.changeTokenBalances(
          testToken,
          [maker, taker],
          [takerAmount, takerAmount.mul(-1)]
        );
      }
    });

    it("Only the taker can execute the activate function.", async function () {
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

      // Add token address to allow list.
      await offerManager
        .connect(owner)
        .addTokenAddressToAllowList([takerTokenAddress]);

      const witness = calcWitness(owner);

      await offerManager
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
        );

      const offerId = 0;
      await testToken.connect(owner).transfer(taker.address, takerAmount);
      await testToken.connect(taker).approve(offerManager.address, takerAmount);
      const tx = offerManager.activate(offerId);
      await expect(tx).to.be.revertedWith(
        "offers can be activated by its taker"
      );
    });
    it("If the taker token address is 0 and the token amount is incorrect, an error is generated.", async function () {
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

      // Add token address to allow list.
      await offerManager
        .connect(owner)
        .addTokenAddressToAllowList([takerTokenAddress]);

      const witness = calcWitness(owner);

      await offerManager
        .connect(maker)
        [REGISTER_FUNC_V2](
          makerIntmaxAddress,
          makerAssetId,
          makerAmount,
          taker.address,
          takerIntmaxAddress,
          ethers.constants.AddressZero,
          takerAmount,
          witness
        );

      const offerId = 0;
      await testToken.connect(owner).transfer(taker.address, takerAmount);
      await testToken.connect(taker).approve(offerManager.address, takerAmount);
      const tx = offerManager.connect(taker).activate(offerId);
      await expect(tx).to.be.revertedWith(
        "please send just the amount needed to activate"
      );
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
          ZERO_ADDRESS,
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
        expect(offer.takerTokenAddress).to.be.equal(ZERO_ADDRESS);
        expect(offer.takerAmount).to.be.equal(takerAmount.toString());
        expect(offer.isActivated).to.be.equal(true); // activated -> isActivated
      }

      await offerManagerV2
        .connect(owner)
        .addTokenAddressToAllowList([ZERO_ADDRESS]);

      const witness = calcWitness(owner);
      await offerManagerV2
        .connect(maker)
        [REGISTER_FUNC_V2](
          makerIntmaxAddress,
          makerAssetId,
          makerAmount,
          taker.address,
          takerIntmaxAddress,
          ZERO_ADDRESS,
          takerAmount,
          witness
        );

      // const OfferManagerV3 = await ethers.getContractFactory(
      //   "OfferManagerV3"
      // );
      // const offerManagerV3 = await upgrades.upgradeProxy(
      //   offerManagerProxyAddress,
      //   OfferManagerV3
      // );

      // await expect(
      //   offerManagerV3.connect(taker).activate(1, { value: takerAmount })
      // )
      //   .to.emit(offerManagerV3, "OfferActivated")
      //   .withArgs(1, takerIntmaxAddress);

      // {
      //   const offer = await offerManagerV3.offers(1);
      //   expect(offer.maker).to.be.equal(maker.address);
      //   expect(offer.makerIntmaxAddress).to.be.equal(makerIntmaxAddress);
      //   expect(offer.makerAssetId).to.be.equal(makerAssetId);
      //   expect(offer.makerAmount).to.be.equal(makerAmount.toString());
      //   expect(offer.taker).to.be.equal(taker.address);
      //   expect(offer.takerIntmaxAddress).to.be.equal(takerIntmaxAddress);
      //   expect(offer.takerTokenAddress).to.be.equal(ZERO_ADDRESS);
      //   expect(offer.takerAmount).to.be.equal(takerAmount.toString());
      //   expect(offer.isActivated).to.be.equal(true); // activated -> isActivated
      // }
    });
  });
});
