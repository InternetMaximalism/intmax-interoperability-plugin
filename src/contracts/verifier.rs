use ethers::contract::abigen;

abigen!(
    VerifierContract,
    "./contracts/compiled-artifacts/contracts/SimpleVerifier.sol/SimpleVerifier.json"
);

abigen!(
    MerkleTreeContract,
    "./contracts/compiled-artifacts/contracts/utils/MerkleTree.sol/MerkleTree.json"
);
