import { ethers } from "hardhat";

// Deploy contracts for testing.
async function main() {
  const OfferManager = await ethers.getContractFactory("OfferManagerV2Test");
  const offerManager = await OfferManager.deploy();
  await offerManager.deployed();

  console.log(`Deploy a OfferManager contract: ${offerManager.address}`);

  const OfferManagerReverse = await ethers.getContractFactory(
    "OfferManagerReverseV2Test"
  );
  const offerManagerReverse = await OfferManagerReverse.deploy();
  await offerManagerReverse.deployed();

  console.log(
    `Deploy a OfferManagerReverse contract: ${offerManagerReverse.address}`
  );

  const networkIndex =
    "0x0000000000000000000000000000000000000000000000000000000000000002";
  const Verifier = await ethers.getContractFactory("SimpleVerifierTest");
  const verifier = await Verifier.deploy(networkIndex);

  console.log(`Deploy a Verifier contract: ${verifier.address}`);

  await offerManager.changeVerifier(verifier.address);
  await offerManagerReverse.changeVerifier(verifier.address);

  const owner = await offerManagerReverse.owner();
  console.log("owner:", owner);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
