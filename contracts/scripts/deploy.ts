import { ethers } from "hardhat";

async function main() {
  const OfferManager = await ethers.getContractFactory("OfferManager");
  const offerManager = await OfferManager.deploy();

  await offerManager.deployed();

  console.log(`Deploy a OfferManager contract: ${offerManager.address}`);

  const OfferManagerReverse = await ethers.getContractFactory(
    "OfferManagerReverse"
  );
  const offerManagerReverse = await OfferManagerReverse.deploy();

  await offerManagerReverse.deployed();

  console.log(
    `Deploy a OfferManagerReverse contract: ${offerManagerReverse.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
