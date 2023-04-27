// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./VerifierInterface.sol";
import "./utils/MerkleTree.sol";
import "./utils/Poseidon.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleVerifier is VerifierInterface, Ownable {
    bytes32 public immutable networkIndex;

    constructor(bytes32 networkIndex_) {
        networkIndex = networkIndex_;
    }

    function verifyAssets(
        Asset[] calldata assets,
        bytes32 recipient,
        bytes calldata witness
    ) external view returns (bool ok) {
        (
            Asset[] memory signedAssets,
            bytes32 signedRecipient,
            MerkleTree.MerkleProof memory diffTreeInclusionProof,
            BlockHeader memory blockHeader,
            bytes memory signature
        ) = abi.decode(
                witness,
                (Asset[], bytes32, MerkleTree.MerkleProof, BlockHeader, bytes)
            );

        require(recipient == signedRecipient, "Not same recipient");

        for (uint256 i = 0; i < assets.length; i++) {
            require(
                assets[i].tokenAddress == signedAssets[i].tokenAddress,
                "Not same asset: tokenAddress"
            );
            require(
                assets[i].tokenId == signedAssets[i].tokenId,
                "Not same asset: tokenId"
            );
            require(
                assets[i].amount == signedAssets[i].amount,
                "Not same asset: amount"
            );
        }

        // TODO: use only one time
        bytes memory message = abi.encode(
            assets,
            recipient,
            diffTreeInclusionProof,
            blockHeader
        );
        bytes32 hashedMessage = ECDSA.toEthSignedMessageHash(message);
        address signer = ECDSA.recover(hashedMessage, signature);
        require(signer == owner(), "Fail to verify aggregator's signature.");

        ok = true;
    }

    function calcWitness(
        Asset[] calldata assets,
        bytes32 recipient,
        MerkleTree.MerkleProof calldata diffTreeInclusionProof,
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
        MerkleTree.MerkleProof calldata diffTreeInclusionProof,
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
