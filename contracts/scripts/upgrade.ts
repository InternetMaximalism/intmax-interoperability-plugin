import { ethers, upgrades } from "hardhat";

// `OFFER_MANAGER_PROXY=<address> OFFER_MANAGER_REVERSE_PROXY=<address> npx hardhat run ./scripts/upgrade.ts --network <network-name>`
async function main() {
  const offerManagerProxyAddress = process.env.OFFER_MANAGER_PROXY!;
  const OfferManager = await ethers.getContractFactory("OfferManager");
  const offerManager = await upgrades.upgradeProxy(
    offerManagerProxyAddress,
    OfferManager
  );

  await offerManager.deployed();

  console.log(`Upgrade a OfferManager contract: ${offerManager.address}`);

  const offerManagerReverseProxyAddress =
    process.env.OFFER_MANAGER_REVERSE_PROXY!;
  const OfferManagerReverse = await ethers.getContractFactory(
    "OfferManagerReverse"
  );
  const offerManagerReverse = await upgrades.upgradeProxy(
    offerManagerReverseProxyAddress,
    OfferManagerReverse
  );

  await offerManagerReverse.deployed();

  console.log(
    `Upgrade a OfferManagerReverse contract: ${offerManagerReverse.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
