use ethers::contract::abigen;

abigen!(
    VerifierContract,
    "./contracts/compiled-artifacts/contracts/Verifier.test.sol/VerifierTest.json"
);

abigen!(
    MerkleTreeContract,
    "./contracts/compiled-artifacts/contracts/utils/MerkleTree.sol/MerkleTree.json"
);
