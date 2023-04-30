import { ethers, upgrades, network } from "hardhat";

// `OFFER_MANAGER_PROXY=<address> OFFER_MANAGER_REVERSE_PROXY=<address> npx hardhat run ./scripts/upgradeV2.ts --network <network-name>`
async function main() {
  const offerManagerProxyAddress = process.env.OFFER_MANAGER_PROXY!;
  const [deployer] = await ethers.getSigners();
  const OfferManager = await ethers.getContractFactory("OfferManagerV2");
  const offerManager = await upgrades.upgradeProxy(
    offerManagerProxyAddress,
    OfferManager,
    {
      call: {
        fn: "initializeV2",
        args: [deployer.address],
      },
    }
  );

  await offerManager.deployed();

  console.log(`Upgrade a OfferManager contract: ${offerManager.address}`);

  const offerManagerReverseProxyAddress =
    process.env.OFFER_MANAGER_REVERSE_PROXY!;
  const OfferManagerReverse = await ethers.getContractFactory(
    "OfferManagerReverseV2"
  );
  const offerManagerReverse = await upgrades.upgradeProxy(
    offerManagerReverseProxyAddress,
    OfferManagerReverse
  );

  await offerManagerReverse.deployed();

  console.log(
    `Upgrade a OfferManagerReverse contract: ${offerManagerReverse.address}`
  );

  {
    const owner = await offerManager.owner();
    console.log("owner:", owner);
  }
  {
    const owner = await offerManagerReverse.owner();
    console.log("owner:", owner);
  }

  let networkIndex;
  switch (network.name) {
    case "scrollalpha":
      networkIndex =
        "0x0000000000000000000000000000000000000000000000000000000000000001";
      break;
    case "polygonzkevmtest":
      networkIndex =
        "0x0000000000000000000000000000000000000000000000000000000000000002";
      break;
    default:
      networkIndex =
        "0x0000000000000000000000000000000000000000000000000000000000000002";
  }
  console.log("networkIndex:", networkIndex);
  const Verifier = await ethers.getContractFactory("SimpleVerifier");
  const verifier = await upgrades.deployProxy(Verifier, [networkIndex]);

  await verifier.deployed();

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
