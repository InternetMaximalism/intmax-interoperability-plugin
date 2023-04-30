// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./VerifierInterface.sol";
import "./utils/MerkleTreeInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SimpleVerifier is VerifierInterface, OwnableUpgradeable {
    /**
     * @notice This variable is the network index used to identify the chain.
     */
    bytes32 public networkIndex;

    /**
     * @notice The function initializes the network index and call the initializer function of OwnableUpgradeable contract.
     * @dev This function should be executed at the same time as this contract is deployed.
     */
    function initialize(bytes32 networkIndex_) public virtual initializer {
        networkIndex = networkIndex_;
        __Ownable_init();
    }

    /**
     * @inheritdoc VerifierInterface
     */
    function verifyAssets(
        Asset[] calldata assets,
        bytes32 recipient,
        bytes calldata witness
    ) external view virtual returns (bool ok) {
        // Decode given `witness`.
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

        // Ensure the `recipient` is the same as the recipient in the `witness`.
        require(recipient == signedRecipient, "Not same recipient");

        // Compare each asset in the `assets` with its corresponding asset in the `witness`.
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

        // Create a message from the `assets`, `recipient`, `diffTreeInclusionProof`, and `blockHeader`, and hash it.
        bytes memory message = abi.encode(
            assets,
            recipient,
            diffTreeInclusionProof,
            blockHeader
        );
        bytes32 hashedMessage = ECDSA.toEthSignedMessageHash(message);

        // Recover the address of the signer from the hashed message and signature.
        address signer = ECDSA.recover(hashedMessage, signature);

        // Ensure the signer is the owner of the contract.
        require(signer == owner(), "Fail to verify aggregator's signature.");

        ok = true;
    }
}
