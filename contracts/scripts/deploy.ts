import { ethers, upgrades } from "hardhat";

async function main() {
  const networkIndex =
    "0x0000000000000000000000000000000000000000000000000000000000000002";
  const Verifier = await ethers.getContractFactory("VerifierTest");
  const verifier = await Verifier.deploy(networkIndex);

  console.log(`Deploy a Verifier contract: ${verifier.address}`);

  const OfferManager = await ethers.getContractFactory("OfferManagerV2");
  const offerManager = await upgrades.deployProxy(OfferManager);
  await offerManager.deployed();
  await offerManager.changeVerifier(verifier.address);

  console.log(`Deploy a OfferManager contract: ${offerManager.address}`);

  const OfferManagerReverse = await ethers.getContractFactory(
    "OfferManagerReverseV2"
  );
  const offerManagerReverse = await upgrades.deployProxy(OfferManagerReverse);
  await offerManagerReverse.deployed();
  await offerManagerReverse.changeVerifier(verifier.address);

  console.log(
    `Deploy a OfferManagerReverse contract: ${offerManagerReverse.address}`
  );

  const owner = await offerManagerReverse.owner();
  console.log("owner:", owner);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
