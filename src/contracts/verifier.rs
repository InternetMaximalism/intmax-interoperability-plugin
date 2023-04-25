use ethers::contract::abigen;

abigen!(
    VerifierContract,
    "./contracts/compiled-artifacts/contracts/Verifier.test.sol/VerifierTest.json"
);
