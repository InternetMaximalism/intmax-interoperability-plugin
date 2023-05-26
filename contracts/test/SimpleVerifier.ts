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
    const [owner, other] = await ethers.getSigners();

    const { recipient } = sampleWitness;
    const networkIndex = recipient;

    const Verifier = await ethers.getContractFactory("SimpleVerifierTest");
    const verifier = await Verifier.deploy(networkIndex);

    return { verifier, networkIndex, owner, other };
  }

  describe("verifyAsset", function () {
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
      });
      it("some assets", async function () {
        const { verifier, networkIndex, owner } = await loadFixture(
          deployVerifier
        );

        const {
          diffTreeInclusionProof,
          blockHeader,
          tokenAddress,
          tokenId,
          tokenAmount,
          tokenAddress2,
          tokenId2,
          tokenAmount2,
        } = sampleWitness;

        const recipient = networkIndex;
        const asset = {
          tokenAddress,
          tokenId,
          amount: tokenAmount,
        };
        const asset2 = {
          tokenAddress: tokenAddress2,
          tokenId: tokenId2,
          amount: tokenAmount2,
        };
        const abiEncoder = new ethers.utils.AbiCoder();
        const message = abiEncoder.encode(
          [
            `${assetStructType}[]`,
            "bytes32",
            merkleProofStructType,
            blockHeaderStructType,
          ],
          [[asset, asset2], recipient, diffTreeInclusionProof, blockHeader]
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
          [[asset, asset2], recipient, diffTreeInclusionProof, blockHeader, signature]
        );

        expect(
          await verifier.verifyAssets([asset, asset2], recipient, witness)
        ).to.be.equals(true);
      });
    });
    describe("fail", function () {
      it("illegal signature", async function () {
        const { verifier, networkIndex, other } = await loadFixture(
          deployVerifier
        );

        const {
          diffTreeInclusionProof,
          blockHeader,
          tokenAddress,
          tokenId,
          tokenAmount,
          // nonce,
          // recipientMerkleSiblings,
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
        const signature = await other.signMessage(messageBytes);

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
          verifier.verifyAssets([asset], recipient, witness)
        ).to.be.revertedWith("Fail to verify aggregator's signature.");
      });
      it("illegal token address", async function () {
        const { verifier, networkIndex, owner } = await loadFixture(
          deployVerifier
        );

        const {
          diffTreeInclusionProof,
          blockHeader,
          tokenAddress,
          tokenId,
          tokenAmount,
          tokenAddress2,
          tokenAddress3,
          tokenId2,
          tokenAmount2,
        } = sampleWitness;

        const recipient = networkIndex;
        const asset = {
          tokenAddress,
          tokenId,
          amount: tokenAmount,
        };
        const asset2 = {
          tokenAddress: tokenAddress2,
          tokenId: tokenId2,
          amount: tokenAmount2,
        };
        const abiEncoder = new ethers.utils.AbiCoder();
        const message = abiEncoder.encode(
          [
            `${assetStructType}[]`,
            "bytes32",
            merkleProofStructType,
            blockHeaderStructType,
          ],
          [[asset, asset2], recipient, diffTreeInclusionProof, blockHeader]
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
          [[asset, asset2], recipient, diffTreeInclusionProof, blockHeader, signature]
        );
        const dummyAsset2 = {
          tokenAddress: tokenAddress3,
          tokenId: tokenId2,
          amount: tokenAmount2,
        };
        await expect(
          verifier.verifyAssets([asset, dummyAsset2], recipient, witness)
        ).to.be.revertedWith("Not same asset: tokenAddress");
      });
      it("illegal token id", async function () {
        const { verifier, networkIndex, owner } = await loadFixture(
          deployVerifier
        );

        const {
          diffTreeInclusionProof,
          blockHeader,
          tokenAddress,
          tokenId,
          tokenAmount,
          tokenAddress2,
          tokenId2,
          tokenId3,
          tokenAmount2,
        } = sampleWitness;

        const recipient = networkIndex;
        const asset = {
          tokenAddress,
          tokenId,
          amount: tokenAmount,
        };
        const asset2 = {
          tokenAddress: tokenAddress2,
          tokenId: tokenId2,
          amount: tokenAmount2,
        };
        const abiEncoder = new ethers.utils.AbiCoder();
        const message = abiEncoder.encode(
          [
            `${assetStructType}[]`,
            "bytes32",
            merkleProofStructType,
            blockHeaderStructType,
          ],
          [[asset, asset2], recipient, diffTreeInclusionProof, blockHeader]
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
          [[asset, asset2], recipient, diffTreeInclusionProof, blockHeader, signature]
        );
        const dummyAsset2 = {
          tokenAddress: tokenAddress2,
          tokenId: tokenId3,
          amount: tokenAmount2,
        };
        await expect(
          verifier.verifyAssets([asset, dummyAsset2], recipient, witness)
        ).to.be.revertedWith("Not same asset: tokenId");
      });
      it("illegal amount", async function () {
        const { verifier, networkIndex, owner } = await loadFixture(
          deployVerifier
        );

        const {
          diffTreeInclusionProof,
          blockHeader,
          tokenAddress,
          tokenId,
          tokenAmount,
          tokenAddress2,
          tokenId2,
          tokenAmount2,
          tokenAmount3
        } = sampleWitness;

        const recipient = networkIndex;
        const asset = {
          tokenAddress,
          tokenId,
          amount: tokenAmount,
        };
        const asset2 = {
          tokenAddress: tokenAddress2,
          tokenId: tokenId2,
          amount: tokenAmount2,
        };
        const abiEncoder = new ethers.utils.AbiCoder();
        const message = abiEncoder.encode(
          [
            `${assetStructType}[]`,
            "bytes32",
            merkleProofStructType,
            blockHeaderStructType,
          ],
          [[asset, asset2], recipient, diffTreeInclusionProof, blockHeader]
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
          [[asset, asset2], recipient, diffTreeInclusionProof, blockHeader, signature]
        );
        const dummyAsset2 = {
          tokenAddress: tokenAddress2,
          tokenId: tokenId2,
          amount: tokenAmount3,
        };
        await expect(
          verifier.verifyAssets([asset, dummyAsset2], recipient, witness)
        ).to.be.revertedWith("Not same asset: amount");
      });
      it("Not same recipient", async function () {
        const { verifier, networkIndex, owner } = await loadFixture(
          deployVerifier
        );

        const {
          diffTreeInclusionProof,
          blockHeader,
          tokenAddress,
          tokenId,
          tokenAmount,
          recipient2
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
        await expect(
          verifier.verifyAssets([asset], recipient2, witness)
        ).to.be.revertedWith("Not same recipient");
      });
    });
  });
});
