import { ethers } from "hardhat";

async function main() {
  const OfferManager = await ethers.getContractFactory("OfferManager");
  const offerManager = await OfferManager.deploy();

  await offerManager.deployed();

  console.log(`Deploy a OfferManager contract: ${offerManager.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
