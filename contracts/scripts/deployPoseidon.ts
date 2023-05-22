import { ethers } from "hardhat";

// Deploy a Poseidon contract for testing.
async function main() {
  const Poseidon = await ethers.getContractFactory("GoldilocksPoseidon");
  const poseidon = await Poseidon.deploy();

  console.log(`Deploy a Poseidon contract: ${poseidon.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
