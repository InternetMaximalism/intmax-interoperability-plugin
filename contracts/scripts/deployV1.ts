import { ethers, upgrades } from "hardhat";

async function main() {
  const OfferManager = await ethers.getContractFactory("OfferManager");
  const offerManager = await upgrades.deployProxy(OfferManager);

  await offerManager.deployed();

  // デプロイの後、verifyをする流れになるかと思います。
  // verifyのため、デプロイしたタイミングでlogicのアドレスも同時に取得すると色々捗ります
	// const filter = offerManager.filters.Upgraded()
	// const events = await offerManager.queryFilter(filter)
	// console.log('logic was deployed to:', events[0].args!.implementation)
  // こんな感じでロジックの方のアドレスがわかります。
  console.log(`Deploy a OfferManager contract: ${offerManager.address}`);

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
