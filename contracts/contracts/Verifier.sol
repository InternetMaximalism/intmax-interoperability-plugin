// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./utils/MerkleTree.sol";
import "./utils/Poseidon.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Verifier is MerkleTree, Ownable {
    bytes32 immutable networkIndex;

    struct Asset {
        bytes32 recipient;
        bytes32 tokenAddress;
        bytes32 tokenId;
        uint256 amount;
    }

    struct BlockHeader {
        bytes32 blockNumber; // little endian
        bytes32 prevBlockHash;
        bytes32 blockHeadersDigest; // block header tree root
        bytes32 transactionsDigest; // state diff tree root
        bytes32 depositDigest; // deposit tree root (include scroll root)
        bytes32 proposedWorldStateDigest;
        bytes32 approvedWorldStateDigest;
        bytes32 latestAccountDigest; // latest account tree
    }

    constructor(bytes32 networkIndex_) {
        networkIndex = networkIndex_;
    }

    function _calcLeafHash(
        bytes32 key,
        bytes32 value
    ) internal view returns (bytes32 leafHash) {
        uint256[4] memory a_hash_out = decodeHashOut(key);
        uint256[4] memory b_hash_out = decodeHashOut(value);
        uint256[] memory state = new uint256[](12);
        state[0] = a_hash_out[0];
        state[1] = a_hash_out[1];
        state[2] = a_hash_out[2];
        state[3] = a_hash_out[3];
        state[4] = b_hash_out[0];
        state[5] = b_hash_out[1];
        state[6] = b_hash_out[2];
        state[7] = b_hash_out[3];
        state[8] = 1;
        state[9] = 1;
        state[11] = 1;
        state = hash_n_to_m_no_pad(state, 4);
        uint256[4] memory output;
        output[0] = state[0];
        output[1] = state[1];
        output[2] = state[2];
        output[3] = state[3];
        leafHash = encodeHashOut(output);
    }

    function _calcTransactionHash(
        Asset[] memory assets,
        bytes32[] memory recipientMerkleSiblings,
        bytes32 nonce
    ) internal view returns (bytes32 transactionHash) {
        require(assets.length == 1);

        bytes32 amountBytes = abi.decode(
            abi.encode(assets[0].amount),
            (bytes32)
        );
        bytes32 innerInnerAssetRoot = _calcLeafHash(
            assets[0].tokenId,
            amountBytes
        );
        bytes32 innerAssetRoot = _calcLeafHash(
            assets[0].tokenAddress,
            innerInnerAssetRoot
        );
        bytes32 recipientLeaf = _calcLeafHash(
            assets[0].recipient,
            innerAssetRoot
        );
        uint256 recipientIndexRev = abi.decode(
            abi.encode(assets[0].recipient),
            (uint256)
        );
        uint256 recipientIndex = 0;
        for (uint256 i = 0; i < recipientMerkleSiblings.length; i++) {
            recipientIndex <<= 1;
            recipientIndex += recipientIndexRev & 1;
            recipientIndexRev >>= 1;
        }
        MerkleProof memory recipientMerkleProof = MerkleProof(
            recipientIndex,
            recipientLeaf,
            recipientMerkleSiblings
        );
        bytes32 diffRoot = _computeMerkleRoot(recipientMerkleProof);
        transactionHash = two_to_one(diffRoot, nonce);
    }

    function _calcBlockHash(
        BlockHeader memory blockHeader
    ) internal view returns (bytes32 blockHash) {
        blockHash = two_to_one(
            blockHeader.transactionsDigest,
            blockHeader.depositDigest
        );

        bytes32 a = two_to_one(
            blockHeader.blockNumber,
            blockHeader.latestAccountDigest
        );
        bytes32 b = two_to_one(
            blockHeader.depositDigest,
            blockHeader.transactionsDigest
        );
        bytes32 c = two_to_one(a, b);
        bytes32 d = two_to_one(
            blockHeader.proposedWorldStateDigest,
            blockHeader.approvedWorldStateDigest
        );
        bytes32 e = two_to_one(c, d);

        blockHash = two_to_one(blockHeader.blockHeadersDigest, e);
    }

    function _verifyBlockHash(
        bytes32 blockHash,
        address aggregator,
        bytes memory signature
    ) internal pure {
        bytes32 hashedMessage = ECDSA.toEthSignedMessageHash(blockHash);
        address signer = ECDSA.recover(hashedMessage, signature);
        require(aggregator == signer, "Fail to verify signature.");
    }

    function _verifyAssetRoot(
        bytes32 blockHash,
        bytes32 txHash,
        MerkleTree.MerkleProof memory diffTreeInclusionProof, // link transactions digest and asset root
        BlockHeader memory blockHeader // link block hash and transactions digest
    ) internal view {
        require(
            txHash == diffTreeInclusionProof.value,
            "Fail to verify asset root"
        );
        bytes32 transactionsDigest = _computeMerkleRootRbo(
            diffTreeInclusionProof
        );
        require(
            transactionsDigest == blockHeader.transactionsDigest,
            "Fail to verify Merkle proof"
        );
        bytes32 expectedBlockHash = _calcBlockHash(blockHeader);
        require(expectedBlockHash == blockHash, "Fail to verify block hash.");
    }

    function _verifyAsset(
        bytes32 txHash,
        Asset memory asset,
        bytes32[] memory recipientMerkleSiblings,
        bytes32 nonce
    ) internal view {
        Asset[] memory assets = new Asset[](1);
        assets[0] = asset;
        bytes32 expectedTxHash = _calcTransactionHash(
            assets,
            recipientMerkleSiblings,
            nonce
        );
        require(expectedTxHash == txHash, "Fail to verify asset root");
    }

    function _verify(
        bytes32 blockHash,
        Asset memory asset,
        address aggregator,
        bytes32 nonce,
        bytes32[] memory recipientMerkleSiblings,
        MerkleTree.MerkleProof memory diffTreeInclusionProof,
        BlockHeader memory blockHeader,
        bytes memory signature // (r, s, v)
    ) internal view returns (bool ok) {
        Asset[] memory assets = new Asset[](1);
        assets[0] = asset;
        bytes32 txHash = _calcTransactionHash(
            assets,
            recipientMerkleSiblings,
            nonce
        );
        _verifyAssetRoot(
            blockHash,
            txHash,
            diffTreeInclusionProof,
            blockHeader
        );
        _verifyBlockHash(blockHash, aggregator, signature);

        ok = true;
    }

    function verify(
        bytes32 blockHash,
        Asset calldata asset,
        bytes calldata witness
    ) external view returns (bool ok) {
        (
            bytes32 nonce,
            bytes32[] memory recipientMerkleSiblings,
            MerkleTree.MerkleProof memory diffTreeInclusionProof,
            BlockHeader memory blockHeader,
            bytes memory signature
        ) = abi.decode(
                witness,
                (bytes32, bytes32[], MerkleTree.MerkleProof, BlockHeader, bytes)
            );

        // require(asset.recipient == networkIndex, "invalid network index");
        address aggregator = owner();
        ok = _verify(
            blockHash,
            asset,
            aggregator,
            nonce,
            recipientMerkleSiblings,
            diffTreeInclusionProof,
            blockHeader,
            signature
        );
    }
}
