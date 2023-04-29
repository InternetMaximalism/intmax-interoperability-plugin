// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface MerkleTreeInterface {
    struct MerkleProof {
        uint256 index;
        bytes32 value;
        bytes32[] siblings;
    }
}
