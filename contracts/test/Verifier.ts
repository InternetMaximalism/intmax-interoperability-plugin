import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { sampleWitness } from "./sampleData";

describe("Verifier", function () {
  async function deployVerifier() {
    // Contracts are deployed using the first signer/account by default
    const [owner] = await ethers.getSigners();

    const { recipient } = sampleWitness;
    const networkIndex = recipient;

    const Verifier = await ethers.getContractFactory("VerifierTest");
    const verifier = await Verifier.deploy(networkIndex);

    return { verifier, networkIndex, owner };
  }

  describe("verify", function () {
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

      const asset = {
        recipient: networkIndex,
        tokenAddress,
        tokenId,
        amount: tokenAmount,
      };

      const messageBytes = Buffer.from(sampleWitness.blockHash.slice(2), "hex");
      const signature = await owner.signMessage(messageBytes);
      await verifier.updateTransactionsDigest(blockHeader, signature);
      const witness = await verifier.calcWitness(
        nonce,
        recipientMerkleSiblings,
        diffTreeInclusionProof,
        blockHeader
      );
      expect(await verifier.verifyAsset(asset, witness)).to.be.equals(true);
      // expect(await verifier.verifyBlockHash(blockHash, signature)).to.be.equals(
      //   true
      // );
    });
  });
});