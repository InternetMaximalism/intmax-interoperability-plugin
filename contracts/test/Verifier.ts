import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  blockHeaderStructType,
  merkleProofStructType,
  sampleWitness,
} from "./sampleData";

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
    describe("success", function () {
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

        const messageBytes = Buffer.from(
          sampleWitness.blockHash.slice(2),
          "hex"
        );
        const signature = await owner.signMessage(messageBytes);
        await verifier.updateTransactionsDigest(blockHeader, signature);

        const abiCoder = new ethers.utils.AbiCoder();
        const witness = abiCoder.encode(
          [
            "bytes32",
            "bytes32[]",
            merkleProofStructType,
            blockHeaderStructType,
          ],
          [nonce, recipientMerkleSiblings, diffTreeInclusionProof, blockHeader]
        );
        expect(
          await verifier.verifyAssets([asset], recipient, witness)
        ).to.be.equals(true);
      });
    });
    describe("fail", function () {
      it("Transactions digest was not registered", async function () {
        const { verifier, networkIndex } = await loadFixture(deployVerifier);

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

        const abiCoder = new ethers.utils.AbiCoder();
        const witness = abiCoder.encode(
          [
            "bytes32",
            "bytes32[]",
            merkleProofStructType,
            blockHeaderStructType,
          ],
          [nonce, recipientMerkleSiblings, diffTreeInclusionProof, blockHeader]
        );
        await expect(
          verifier.verifyAssets([asset], recipient, witness)
        ).to.be.revertedWith("Transactions digest was not registered");
      });
      it("Only one type of asset is available", async function () {
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

        const messageBytes = Buffer.from(
          sampleWitness.blockHash.slice(2),
          "hex"
        );
        const signature = await owner.signMessage(messageBytes);
        await verifier.updateTransactionsDigest(blockHeader, signature);

        const abiCoder = new ethers.utils.AbiCoder();
        const witness = abiCoder.encode(
          [
            "bytes32",
            "bytes32[]",
            merkleProofStructType,
            blockHeaderStructType,
          ],
          [nonce, recipientMerkleSiblings, diffTreeInclusionProof, blockHeader]
        );
        await expect(
          verifier.verifyAssets([asset, asset], recipient, witness)
        ).to.be.revertedWith("Only one type of asset is available");
      });
      it("Fail to verify transaction hash", async function () {
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

        const messageBytes = Buffer.from(
          sampleWitness.blockHash.slice(2),
          "hex"
        );
        const signature = await owner.signMessage(messageBytes);
        await verifier.updateTransactionsDigest(blockHeader, signature);

        const abiCoder = new ethers.utils.AbiCoder();
        const witness = abiCoder.encode(
          [
            "bytes32",
            "bytes32[]",
            merkleProofStructType,
            blockHeaderStructType,
          ],
          [
            nonce,
            recipientMerkleSiblings,
            {
              ...diffTreeInclusionProof,
              value:
                "0x0eb318137a57bc2291eb5dbcbe8b10fc3d46e45933c2e14e9030880b380bac98",
            },
            blockHeader,
          ]
        );
        await expect(
          verifier.verifyAssets([asset], recipient, witness)
        ).to.be.revertedWith("Fail to verify transaction hash");
      });
      it("Fail to verify transactions digest", async function () {
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

        const messageBytes = Buffer.from(
          sampleWitness.blockHash.slice(2),
          "hex"
        );
        const signature = await owner.signMessage(messageBytes);
        await verifier.updateTransactionsDigest(blockHeader, signature);

        const abiCoder = new ethers.utils.AbiCoder();
        const witness = abiCoder.encode(
          [
            "bytes32",
            "bytes32[]",
            merkleProofStructType,
            blockHeaderStructType,
          ],
          [
            nonce,
            recipientMerkleSiblings,
            {
              ...diffTreeInclusionProof,
              siblings: [
                "0xc71603f33a1144ca7953db0ab48808f4c4055e3364a246c33c18a9786cb0b359",
                "0xc71603f33a1144ca7953db0ab48808f4c4055e3364a246c33c18a9786cb0b359",
                "0xc71603f33a1144ca7953db0ab48808f4c4055e3364a246c33c18a9786cb0b359",
                "0xc71603f33a1144ca7953db0ab48808f4c4055e3364a246c33c18a9786cb0b359",
              ],
            },
            blockHeader,
          ]
        );
        await expect(
          verifier.verifyAssets([asset], recipient, witness)
        ).to.be.revertedWith("Fail to verify transactions digest");
      });
      it("Fail to verify aggregator's signature.", async function () {
        const { verifier, owner } = await loadFixture(deployVerifier);

        const { blockHeader } = sampleWitness;

        const messageBytes = Buffer.from(
          sampleWitness.blockHash.slice(2),
          "hex"
        );
        const signature = await owner.signMessage(messageBytes);
        await expect(
          verifier.updateTransactionsDigest(
            {
              ...blockHeader,
              transactionsDigest:
                "0x0eb318137a57bc2291eb5dbcbe8b10fc3d46e45933c2e14e9030880b380bac98",
            },
            signature
          )
        ).to.be.revertedWith("Fail to verify aggregator's signature.");
      });
    });
  });
});
