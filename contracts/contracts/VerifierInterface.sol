// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface VerifierInterface {
    struct Asset {
        bytes32 tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

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

    function networkIndex() external view returns (bytes32);

    function verifyAssets(
        Asset[] calldata assets,
        bytes32 recipient,
        bytes calldata witness
    ) external view returns (bool ok);
}
