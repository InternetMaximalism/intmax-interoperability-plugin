// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Verifier.sol";
import "hardhat/console.sol";

contract VerifierTest is Verifier {
    constructor(bytes32 networkIndex) Verifier(networkIndex) {}

    function getWitness(
        bytes32 nonce,
        bytes32[] calldata recipientMerkleSiblings,
        MerkleTree.MerkleProof calldata diffTreeInclusionProof,
        BlockHeader calldata blockHeader,
        bytes calldata signature // (r, s, v)
    ) external pure returns (bytes memory witness) {
        witness = abi.encode(
            nonce,
            recipientMerkleSiblings,
            diffTreeInclusionProof,
            blockHeader,
            signature
        );
    }

    function testVerify(
        bytes32 blockHash,
        Asset calldata asset,
        address aggregator,
        bytes32 nonce,
        bytes32[] calldata recipientMerkleSiblings,
        MerkleTree.MerkleProof calldata diffTreeInclusionProof,
        BlockHeader calldata blockHeader,
        bytes calldata signature // (r, s, v)
    ) external view returns (bool ok) {
        ok = _verify(
            blockHash,
            asset,
            aggregator,
            nonce,
            recipientMerkleSiblings,
            diffTreeInclusionProof,
            blockHeader,
            signature
        );
    }
}
