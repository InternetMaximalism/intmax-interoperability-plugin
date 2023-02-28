import { ethers } from "hardhat";

async function main() {
  const FlagManager = await ethers.getContractFactory("FlagManager");
  const flagManager = await FlagManager.deploy();

  await flagManager.deployed();

  console.log(`Deploy a FlagManager contract: ${flagManager.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
