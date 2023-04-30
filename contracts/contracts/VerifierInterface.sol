// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface VerifierInterface {
    /**
     * @notice This struct represents asset.
     */
    struct Asset {
        bytes32 tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    /**
     * @notice This struct represents a block header.
     */
    struct BlockHeader {
        uint256 blockNumber; // little endian
        bytes32 prevBlockHash;
        bytes32 blockHeadersDigest; // block header tree root
        bytes32 transactionsDigest; // state diff tree root
        bytes32 depositDigest; // deposit tree root (include scroll root)
        bytes32 proposedWorldStateDigest;
        bytes32 approvedWorldStateDigest;
        bytes32 latestAccountDigest; // latest account tree
    }

    /**
     * @notice This function returns the network index used to identify the chain.
     */
    function networkIndex() external view returns (bytes32);

    /**
     * @notice This function verifies the assets of the recipient.
     * @param assets is an array of Asset struct that contains tokenAddress, tokenId, and amount of the assets.
     * @param recipient is the recipient's INTMAX address.
     * @param witness is a witness that contains a set of assets, recipient, diffTreeInclusionProof, blockHeader and owner's signature.
     * @return ok indicating whether the execution was successful.
     */
    function verifyAssets(
        Asset[] calldata assets,
        bytes32 recipient,
        bytes calldata witness
    ) external view returns (bool ok);
}
