// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./SimpleVerifier.sol";

contract SimpleVerifierTest is SimpleVerifier {
    constructor(bytes32 networkIndex_) {
        initialize(networkIndex_);
    }

    function calcWitness(
        Asset[] calldata assets,
        bytes32 recipient,
        MerkleTreeInterface.MerkleProof calldata diffTreeInclusionProof,
        BlockHeader calldata blockHeader,
        bytes calldata signature
    ) external pure returns (bytes memory witness) {
        witness = abi.encode(
            assets,
            recipient,
            diffTreeInclusionProof,
            blockHeader,
            signature
        );
    }

    function calcSingingMessage(
        Asset[] calldata assets,
        bytes32 recipient,
        MerkleTreeInterface.MerkleProof calldata diffTreeInclusionProof,
        BlockHeader calldata blockHeader
    ) external pure returns (bytes memory signature) {
        signature = abi.encode(
            assets,
            recipient,
            diffTreeInclusionProof,
            blockHeader
        );
    }
}
