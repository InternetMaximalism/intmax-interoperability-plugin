// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Verifier.sol";

// import "hardhat/console.sol";

contract VerifierTest is Verifier {
    constructor(bytes32 networkIndex) Verifier(networkIndex) {}

    function calcWitness(
        bytes32 blockHash,
        bytes32 nonce,
        bytes32[] calldata recipientMerkleSiblings,
        MerkleTree.MerkleProof calldata diffTreeInclusionProof,
        BlockHeader calldata blockHeader
    ) external pure returns (bytes memory witness) {
        witness = abi.encode(
            blockHash,
            nonce,
            recipientMerkleSiblings,
            diffTreeInclusionProof,
            blockHeader
        );
    }

    function testVerifyAsset(
        Asset calldata asset,
        bytes32 blockHash,
        bytes32 nonce,
        bytes32[] calldata recipientMerkleSiblings,
        MerkleTree.MerkleProof calldata diffTreeInclusionProof,
        BlockHeader calldata blockHeader
    ) external view returns (bool ok) {
        ok = _verifyAsset(
            blockHash,
            asset,
            nonce,
            recipientMerkleSiblings,
            diffTreeInclusionProof,
            blockHeader
        );
    }
}
