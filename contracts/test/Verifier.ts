import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Verifier", function () {
  async function deployVerifier() {
    // Contracts are deployed using the first signer/account by default
    const [owner] = await ethers.getSigners();

    const Verifier = await ethers.getContractFactory("VerifierTest");
    const verifier = await Verifier.deploy();

    return { verifier, owner };
  }

  describe("verifyTransaction", function () {
    it("Should execute without errors", async function () {
      const { verifier, owner } = await loadFixture(deployVerifier);
      console.log("owner:", owner.address);

      const diffTreeInclusionProof = {
        index: 0,
        value:
          "0x773dd5bf1bf7e274f11ea9c1b5fd7f6dadcc93cb50f8520f325c649d73686388",
        siblings: [
          "0xc71603f33a1144ca7953db0ab48808f4c4055e3364a246c33c18a9786cb0b359",
          "0x2196fc41328ae503de8f9ad762a30af28d85581b9901b2cfb61a4ad1aaf14fcc",
          "0x67703a0cc73ca54246fb94bfe956c05f9a247cc59da2de6461e00af7295ce05a",
          "0xf522eaa0af88a040167d7cf3bf854d278cc1b30d2e2c09475154921a06462644",
        ],
      };
      const blockHeader = {
        blockNumber:
          "0x000000000000000000000000000000000000000000000000000000000000000e",
        prevBlockHash:
          "0xd69e8ba062dfbdf5506cb39b278fad99072c26ba358f1352062bbe0e7797561a",
        blockHeadersDigest:
          "0x17f4f8aad4e73357da75b58398bc47a027d517948c6907149812eeb63c532e64",
        transactionsDigest:
          "0xe79eb578dbd27373cb6bbc9512fa95ea32889751315d3c9a2c3000adb72de44a",
        depositDigest:
          "0x0c421bb92255b128ad866cbbe6a59e10453add89e9ff862b007c6ac5da2df291",
        proposedWorldStateDigest:
          "0xfbcb8fd6122b9c99446784f5a3a3663252028d461c1886d9ea2cca702dca6ad1",
        approvedWorldStateDigest:
          "0xfbcb8fd6122b9c99446784f5a3a3663252028d461c1886d9ea2cca702dca6ad1",
        latestAccountDigest:
          "0xcbf6871d4eb74cec1512b284b3e9309594f123f0d0264242164b108b72ca674c",
      };
      const blockHash =
        "0x93275bdc7c643a0e10757c4f650f020f10cb1f024335e1cc112039447010189f";
      const messageBytes = Buffer.from(blockHash.slice(2), "hex");
      const signature = await owner.signMessage(messageBytes);
      const txHash = diffTreeInclusionProof.value;
      console.log("txHash:", txHash);
      // const assetRoot = blockHash;
      const tokenAddress =
        "0x000000000000000000000000000000000000000000000000f7c23e5c2d79b6ae";
      // "0xaeb6792d5c3ec2f7000000000000000000000000000000000000000000000000";
      const tokenId =
        "0x0000000000000000000000000000000000000000000000000000000000000000";
      const tokenAmount = 3;
      const asset = {
        recipient:
          // "0x0000000000000000000000000000000000000000000000000000000000000000",
          "0x00000000000000000000000000000000000000000000000010d1cb00b658931e",
        tokenAddress,
        tokenId,
        amount: tokenAmount,
      };
      const nonce =
        "0xa710189dc0d8eb00a46e0411c0b1965192f80c50fbd8cbd51b5c67b26fc9dff1";
      const recipientMerkleSiblings = [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0x99bb2839b542ab8bd432363cc4ebbf9d0623d34d1b2d2ff7e23b803b2ff5c94e",
      ].reverse();
      // const abiCoder = new ethers.utils.AbiCoder();
      // abiCoder.encode([""], );

      console.log("blockHash:", blockHash);
      console.log("signer:", owner.address);
      console.log("signature:", signature);
      // const witness =
      //   "0x0000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000000ed69e8ba062dfbdf5506cb39b278fad99072c26ba358f1352062bbe0e7797561a17f4f8aad4e73357da75b58398bc47a027d517948c6907149812eeb63c532e64e79eb578dbd27373cb6bbc9512fa95ea32889751315d3c9a2c3000adb72de44a0c421bb92255b128ad866cbbe6a59e10453add89e9ff862b007c6ac5da2df291fbcb8fd6122b9c99446784f5a3a3663252028d461c1886d9ea2cca702dca6ad1fbcb8fd6122b9c99446784f5a3a3663252028d461c1886d9ea2cca702dca6ad1cbf6871d4eb74cec1512b284b3e9309594f123f0d0264242164b108b72ca674c00000000000000000000000000000000000000000000000000000000000002400000000000000000000000000000000000000000000000000000000000000000773dd5bf1bf7e274f11ea9c1b5fd7f6dadcc93cb50f8520f325c649d7368638800000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000004c71603f33a1144ca7953db0ab48808f4c4055e3364a246c33c18a9786cb0b3592196fc41328ae503de8f9ad762a30af28d85581b9901b2cfb61a4ad1aaf14fcc67703a0cc73ca54246fb94bfe956c05f9a247cc59da2de6461e00af7295ce05af522eaa0af88a040167d7cf3bf854d278cc1b30d2e2c09475154921a064626440000000000000000000000000000000000000000000000000000000000000041e3847cd9368bc7b727d340097118d069d8fbe0916ba2291e25dd610ffdfcc26521b3a6cad4a3c1e7810650fdbe1eac02c84aa29bd0d7f5fc84fcbd20f7262b611c00000000000000000000000000000000000000000000000000000000000000";
      // expect(
      //   await verifier.testVerify(
      //     blockHash,
      //     asset,
      //     owner.address,
      //     txHash,
      //     nonce,
      //     recipientMerkleSiblings,
      //     diffTreeInclusionProof,
      //     blockHeader,
      //     signature
      //   )
      // ).to.be.equals(true);
      const witness = await verifier.getWitness(
        txHash,
        nonce,
        recipientMerkleSiblings,
        diffTreeInclusionProof,
        blockHeader,
        signature
      );
      expect(
        await verifier.verify(blockHash, asset, owner.address, witness)
      ).to.be.equals(true);
    });
  });
});
