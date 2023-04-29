// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./VerifierInterface.sol";
import "./utils/MerkleTreeInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleVerifier is VerifierInterface, OwnableUpgradeable {
    bytes32 public networkIndex;

    function initialize(bytes32 networkIndex_) public virtual initializer {
        networkIndex = networkIndex_;
        __Ownable_init();
    }

    function verifyAssets(
        Asset[] calldata assets,
        bytes32 recipient,
        bytes calldata witness
    ) external view virtual returns (bool ok) {
        (
            Asset[] memory signedAssets,
            bytes32 signedRecipient,
            MerkleTreeInterface.MerkleProof memory diffTreeInclusionProof,
            BlockHeader memory blockHeader,
            bytes memory signature
        ) = abi.decode(
                witness,
                (
                    Asset[],
                    bytes32,
                    MerkleTreeInterface.MerkleProof,
                    BlockHeader,
                    bytes
                )
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
}
