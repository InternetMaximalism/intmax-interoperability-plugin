import { ethers } from "hardhat";

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

async function main() {
  let tokenAddress = process.env.TEST_TOKEN;
  if (!tokenAddress) {
    const Erc20 = await ethers.getContractFactory("ERC20Test");
    const testToken = await Erc20.deploy();
    await testToken.deployed();

    console.log(`Deploy a ERC20 contract: ${testToken.address}`);

    tokenAddress = testToken.address;
  }

  const offerManagerProxyAddress = process.env.OFFER_MANAGER_PROXY!;
  const offerManagerReverseProxyAddress =
    process.env.OFFER_MANAGER_REVERSE_PROXY!;

  const OfferManager = await ethers.getContractFactory("OfferManagerV2");
  const offerManager = OfferManager.attach(offerManagerProxyAddress);
  await offerManager.deployed();

  console.log(`Attach a OfferManager contract: ${offerManager.address}`);

  {
    const owner = await offerManager.owner();
    console.log("owner:", owner);
  }

  await offerManager.addTokenAddressToAllowList([ZERO_ADDRESS, tokenAddress]);
  // await offerManager.removeTokenAddressFromAllowList([ZERO_ADDRESS]);

  const OfferManagerReverse = await ethers.getContractFactory(
    "OfferManagerReverseV2"
  );
  const offerManagerReverse = OfferManagerReverse.attach(
    offerManagerReverseProxyAddress
  );
  await offerManagerReverse.deployed();

  console.log(
    `Attach a OfferManagerReverse contract: ${offerManagerReverse.address}`
  );

  {
    const owner = await offerManagerReverse.owner();
    console.log("owner:", owner);
  }

  await offerManagerReverse.addTokenAddressToAllowList([
    ZERO_ADDRESS,
    tokenAddress,
  ]);
  // await offerManagerReverse.removeTokenAddressFromAllowList([ZERO_ADDRESS]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
