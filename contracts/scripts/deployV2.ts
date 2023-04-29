import { ethers, upgrades } from "hardhat";

async function main() {
  const OfferManager = await ethers.getContractFactory("OfferManagerV2");
  const offerManager = await upgrades.deployProxy(OfferManager);
  await offerManager.deployed();

  console.log(`Deploy a OfferManager contract: ${offerManager.address}`);

  const OfferManagerReverse = await ethers.getContractFactory(
    "OfferManagerReverseV2"
  );
  const offerManagerReverse = await upgrades.deployProxy(OfferManagerReverse);
  await offerManagerReverse.deployed();

  console.log(
    `Deploy a OfferManagerReverse contract: ${offerManagerReverse.address}`
  );

  {
    const owner = await offerManager.owner();
    console.log("owner:", owner);
  }
  {
    const owner = await offerManagerReverse.owner();
    console.log("owner:", owner);
  }

  const networkIndex =
    "0x0000000000000000000000000000000000000000000000000000000000000002";
  const Verifier = await ethers.getContractFactory("SimpleVerifier");
  const verifier = await upgrades.deployProxy(Verifier, [networkIndex]);

  console.log(`Deploy a Verifier contract: ${verifier.address}`);

  await offerManager.changeVerifier(verifier.address);
  await offerManagerReverse.changeVerifier(verifier.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
