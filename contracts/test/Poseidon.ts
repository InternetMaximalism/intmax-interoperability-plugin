import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Poseidon", function () {
  async function deployVerifier() {
    // Contracts are deployed using the first signer/account by default
    const [owner] = await ethers.getSigners();

    const Verifier = await ethers.getContractFactory("GoldilocksPoseidonOpt");
    const verifier = await Verifier.deploy();

    return { verifier, owner };
  }

  describe("verify", function () {
    it("Should execute without errors", async function () {
      const { verifier } = await loadFixture(deployVerifier);

      const inputs = [1, 2];
      const output = await verifier.hash_n_to_m_no_pad(inputs, 4);
      console.log(output);
    });
  });
});
