import { ethers, upgrades } from "hardhat";

async function main() {
  const OfferManager = await ethers.getContractFactory("OfferManager");
  const offerManager = await upgrades.deployProxy(OfferManager);

  await offerManager.deployed();

  const logic = await offerManager.implementation();
  console.log(`Deploy a OfferManager logic contract: ${logic}`);
  console.log(`Deploy a OfferManager proxy contract: ${offerManager.address}`);

  const OfferManagerReverse = await ethers.getContractFactory(
    "OfferManagerReverse"
  );
  const offerManagerReverse = await upgrades.deployProxy(OfferManagerReverse);

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
