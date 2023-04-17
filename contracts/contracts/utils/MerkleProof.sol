// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Poseidon.sol";

library MerkleProof {
    function verify(
        bytes32[] memory siblings,
        bytes32 root,
        uint256 index,
        bytes32 leaf
    ) internal pure returns (bool) {
        // Check if the computed hash (root) is equal to the provided root
        return computeRoot(siblings, index, leaf) == root;
    }

    function computeRoot(
        bytes32[] memory siblings,
        uint256 index,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < siblings.length; i++) {
            uint256 branchIndex = index & 1;
            index = index >> 1;

            if (branchIndex == 1) {
                // Hash(current computed hash + current element of the proof)
                computedHash = GoldilocksPoseidon.two_to_one(
                    siblings[i],
                    computedHash
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = GoldilocksPoseidon.two_to_one(
                    computedHash,
                    siblings[i]
                );
            }
        }

        return computedHash;
    }
}
