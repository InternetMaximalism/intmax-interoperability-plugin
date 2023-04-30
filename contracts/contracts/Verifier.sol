// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./VerifierInterface.sol";
import "./SimpleVerifier.sol";
import "./utils/MerkleTree.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Verifier is SimpleVerifier, MerkleTree {
    /**
     * @notice This mapping stores the correspondence from block number to transactions digest.
     */
    mapping(uint256 => bytes32) public transactionsDigestHistory;

    constructor(bytes32 networkIndex_) {
        SimpleVerifier.initialize(networkIndex_);
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
        bytes32 recipient,
        bytes32[] memory recipientMerkleSiblings,
        bytes32 nonce
    ) internal view returns (bytes32 transactionHash) {
        require(assets.length == 1);

        bytes32 tokenIdBytes = abi.decode(
            abi.encode(assets[0].tokenId),
            (bytes32)
        );
        bytes32 amountBytes = abi.decode(
            abi.encode(assets[0].amount),
            (bytes32)
        );
        bytes32 innerInnerAssetRoot = _calcLeafHash(tokenIdBytes, amountBytes);
        bytes32 innerAssetRoot = _calcLeafHash(
            assets[0].tokenAddress,
            innerInnerAssetRoot
        );
        bytes32 recipientLeaf = _calcLeafHash(recipient, innerAssetRoot);
        uint256 recipientIndex = abi.decode(abi.encode(recipient), (uint256));
        MerkleProof memory recipientMerkleProof = MerkleProof(
            recipientIndex,
            recipientLeaf,
            recipientMerkleSiblings
        );
        bytes32 diffRoot = _computeMerkleRootRbo(recipientMerkleProof);
        transactionHash = two_to_one(diffRoot, nonce);
    }

    function _calcBlockHash(
        BlockHeader memory blockHeader
    ) internal view returns (bytes32 blockHash) {
        blockHash = two_to_one(
            blockHeader.transactionsDigest,
            blockHeader.depositDigest
        );

        bytes32 blockNumber = abi.decode(
            abi.encode(blockHeader.blockNumber),
            (bytes32)
        );
        bytes32 a = two_to_one(blockNumber, blockHeader.latestAccountDigest);
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

    function _verifyAsset(
        bytes32 transactionsDigest,
        Asset memory asset,
        bytes32 recipient,
        bytes32 nonce,
        bytes32[] memory recipientMerkleSiblings,
        MerkleTree.MerkleProof memory diffTreeInclusionProof
    ) internal view returns (bool ok) {
        Asset[] memory assets = new Asset[](1);
        assets[0] = asset;
        bytes32 txHash = _calcTransactionHash(
            assets,
            recipient,
            recipientMerkleSiblings,
            nonce
        );
        require(
            txHash == diffTreeInclusionProof.value,
            "Fail to verify transaction hash"
        );
        bytes32 expectedTransactionsDigest = _computeMerkleRoot(
            diffTreeInclusionProof
        );
        require(
            expectedTransactionsDigest == transactionsDigest,
            "Fail to verify transactions digest"
        );
        // bytes32 expectedBlockHash = _calcBlockHash(blockHeader);
        // require(expectedBlockHash == blockHash, "Fail to verify block hash.");

        ok = true;
    }

    function _verifyBlockHash(
        bytes32 blockHash,
        bytes calldata witness // (r, s, v)
    ) internal view {
        bytes32 hashedMessage = ECDSA.toEthSignedMessageHash(blockHash);
        address signer = ECDSA.recover(hashedMessage, witness);
        require(signer == owner(), "Fail to verify aggregator's signature.");
    }

    function updateTransactionsDigest(
        BlockHeader memory blockHeader,
        bytes calldata witness
    ) external {
        bytes32 blockHash = _calcBlockHash(blockHeader);
        _verifyBlockHash(blockHash, witness);
        transactionsDigestHistory[blockHeader.blockNumber] = blockHeader
            .transactionsDigest;
    }

    function verifyAssets(
        Asset[] calldata assets,
        bytes32 recipient,
        bytes calldata witness
    ) external view override returns (bool ok) {
        (
            bytes32 nonce,
            bytes32[] memory recipientMerkleSiblings,
            MerkleTree.MerkleProof memory diffTreeInclusionProof,
            BlockHeader memory blockHeader
        ) = abi.decode(
                witness,
                (
                    bytes32,
                    bytes32[],
                    MerkleTreeInterface.MerkleProof,
                    BlockHeader
                )
            );

        bytes32 transactionsDigest = transactionsDigestHistory[
            blockHeader.blockNumber
        ];
        require(
            transactionsDigest != bytes32(0),
            "Transactions digest was not registered"
        );
        require(assets.length == 1, "Only one type of asset is available");

        ok = _verifyAsset(
            transactionsDigest,
            assets[0],
            recipient,
            nonce,
            recipientMerkleSiblings,
            diffTreeInclusionProof
        );
    }
}
