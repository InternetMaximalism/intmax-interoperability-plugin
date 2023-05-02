// SPDX-License-Identifier: MIT
// TODO hardhatのサポート最新Solidityバージョンは0.818なので、全体的に修正した方がいいかもしれない
pragma solidity 0.8.17;

import "./MerkleTreeInterface.sol";
import "./Poseidon.sol";

contract MerkleTree is MerkleTreeInterface, GoldilocksPoseidon {
    // Compure Merkle root.
    function _computeMerkleRoot(
        MerkleProof memory proof
    ) internal view returns (bytes32) {
        bytes32 computedHash = proof.value;
        uint256 index = proof.index;

        // おそらくauditに出したら突っ込まれる部分。
        // siblingsの長さ次第で、計算量がとんでもない的なことを言われると思われる。
        // ただまぁこうしないと、MerkleTreeの実装ができないので、
        // もどかしい。
        // lengthの最大数チェックとかが折衷案かもしれない。
        // (*1)
        for (uint256 i = 0; i < proof.siblings.length; i++) {
            uint256 branchIndex = index & 1;
            index = index >> 1;

            if (branchIndex == 1) {
                computedHash = two_to_one(proof.siblings[i], computedHash);
            } else {
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
        uint256 index = proof.index << (256 - proof.siblings.length);
        // (*1) と同等
        for (uint256 i = proof.siblings.length; i != 0; i--) {
            uint256 branchIndex = (index >> 255) & 1;
            index = index << 1;

            if (branchIndex == 1) {
                computedHash = two_to_one(proof.siblings[i - 1], computedHash);
            } else {
                computedHash = two_to_one(computedHash, proof.siblings[i - 1]);
            }
        }

        return computedHash;
    }
}
