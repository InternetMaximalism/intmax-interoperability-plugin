// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Verifier.sol";

// import "hardhat/console.sol";

contract VerifierTest is Verifier {
    constructor(bytes32 networkIndex) Verifier(networkIndex) {}

    function verifyBlockHash(
        bytes32 blockHash,
        bytes calldata witness // (r, s, v)
    ) external view returns (bool ok) {
        _verifyBlockHash(blockHash, witness);

        ok = true;
    }

    function testVerifyAsset(
        Asset calldata asset,
        bytes32 recipient,
        bytes32 transactionsDigest,
        bytes32 nonce,
        bytes32[] calldata recipientMerkleSiblings,
        MerkleTree.MerkleProof calldata diffTreeInclusionProof
    ) external view returns (bool ok) {
        ok = _verifyAsset(
            transactionsDigest,
            asset,
            recipient,
            nonce,
            recipientMerkleSiblings,
            diffTreeInclusionProof
        );
    }

    function calcWitness(
        bytes32 nonce,
        bytes32[] calldata recipientMerkleSiblings,
        MerkleTree.MerkleProof calldata diffTreeInclusionProof,
        BlockHeader calldata blockHeader
    ) external pure returns (bytes memory witness) {
        witness = abi.encode(
            nonce,
            recipientMerkleSiblings,
            diffTreeInclusionProof,
            blockHeader
        );
    }
}
