use ethers::contract::abigen;

abigen!(
    VerifierContract,
    "./contracts/compiled-artifacts/contracts/VerifierInterface.sol/VerifierInterface.json"
);
