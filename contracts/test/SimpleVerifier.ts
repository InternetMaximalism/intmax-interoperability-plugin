import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  assetStructType,
  blockHeaderStructType,
  merkleProofStructType,
  sampleWitness,
} from "./sampleData";

describe("SimpleVerifier", function () {
  async function deployVerifier() {
    // Contracts are deployed using the first signer/account by default
    const [owner] = await ethers.getSigners();

    const { recipient } = sampleWitness;
    const networkIndex = recipient;

    const Verifier = await ethers.getContractFactory("SimpleVerifierTest");
    const verifier = await Verifier.deploy(networkIndex);

    return { verifier, networkIndex, owner };
  }

  describe("verifyAsset", function () {
    it("Should execute without errors", async function () {
      const { verifier, networkIndex, owner } = await loadFixture(
        deployVerifier
      );

      const {
        diffTreeInclusionProof,
        blockHeader,
        tokenAddress,
        tokenId,
        tokenAmount,
        nonce,
        recipientMerkleSiblings,
      } = sampleWitness;

      const recipient = networkIndex;
      const asset = {
        tokenAddress,
        tokenId,
        amount: tokenAmount,
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

      expect(
        await verifier.verifyAssets([asset], recipient, witness)
      ).to.be.equals(true);
      // expect(await verifier.verifyBlockHash(blockHash, signature)).to.be.equals(
      //   true
      // );
    });
  });
});
