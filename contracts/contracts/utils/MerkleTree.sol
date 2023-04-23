// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Poseidon.sol";

contract MerkleTree is GoldilocksPoseidon {
    struct MerkleProof {
        // bytes32 root;
        uint256 index;
        bytes32 value;
        bytes32[] siblings;
    }

    function _verifyMerkleProof(
        MerkleProof memory proof,
        bytes32 root
    ) internal view returns (bool) {
        // Check if the computed hash (root) is equal to the provided root
        return _computeMerkleRoot(proof) == root;
    }

    // Compure Merkle root.
    function _computeMerkleRoot(
        MerkleProof memory proof
    ) internal view returns (bytes32) {
        bytes32 computedHash = proof.value;
        uint256 index = proof.index;

        for (uint256 i = 0; i < proof.siblings.length; i++) {
            uint256 branchIndex = index & 1;
            index = index >> 1;

            if (branchIndex == 1) {
                // Hash(current computed hash + current element of the proof)
                computedHash = two_to_one(proof.siblings[i], computedHash);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = two_to_one(computedHash, proof.siblings[i]);
            }
        }

        return computedHash;
    }

    // Compure Merkle root in the case that the proof index has reverse bit order.
    function _computeMerkleRootRbo(
        MerkleProof memory proof
    ) internal view returns (bytes32) {
        bytes32 computedHash = proof.value;
        uint256 index = proof.index % (1 << (256 - proof.siblings.length));

        for (uint256 i = 0; i < proof.siblings.length; i++) {
            uint256 branchIndex = index & (1 << 255);
            index = index << 1;

            if (branchIndex == 1) {
                computedHash = two_to_one(proof.siblings[i], computedHash);
            } else {
                computedHash = two_to_one(computedHash, proof.siblings[i]);
            }
        }

        return computedHash;
    }
}
