import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("FlagManager", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFlagManager() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const FlagManager = await ethers.getContractFactory("FlagManagerTest");
    const flagManager = await FlagManager.deploy();

    return { flagManager, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should return the valid next flag ID", async function () {
      const { flagManager } = await loadFixture(deployFlagManager);

      expect(await flagManager.nextFlagId()).to.equal(0);
    });
  });
});
