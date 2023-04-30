// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerReverse.sol";
import "./utils/MerkleTree.sol";
import "./VerifierInterface.sol";

contract OfferManagerReverseV2 is OfferManagerReverse {
    VerifierInterface verifier;
    mapping(bytes32 => bool) public usedTxHashes;

    function changeVerifier(VerifierInterface newVerifier) external onlyOwner {
        verifier = newVerifier;
    }

    function activate(
        uint256 offerId,
        bytes calldata witness
    ) external override returns (bool) {
        Offer memory offer = _offers[offerId];

        // address makerIntmaxAddress = _offers[offerId].makerIntmaxAddress;
        // if (makerIntmaxAddress != address(0)) {
        //     require(
        //         witness.senderIntmax == makerIntmaxAddress,
        //         "offers can be activated by its taker"
        //     );
        // }

        (, , MerkleTree.MerkleProof memory diffTreeInclusionProof, , ) = abi
            .decode(
                witness,
                (
                    VerifierInterface.Asset[],
                    bytes32,
                    MerkleTreeInterface.MerkleProof,
                    VerifierInterface.BlockHeader,
                    bytes
                )
            );
        bytes32 txHash = diffTreeInclusionProof.value;
        require(!usedTxHashes[txHash], "Given witness already used");
        _checkWitness(_offers[offerId], witness);
        usedTxHashes[txHash] = true;

        require(
            _msgSender() == offer.maker,
            "Only the maker can unlock this offer."
        );
        _activate(offerId);

        // The maker transfers token to taker.
        if (offer.takerTokenAddress == address(0)) {
            payable(offer.maker).transfer(offer.takerAmount);
        } else {
            bool success = IERC20(offer.takerTokenAddress).transfer(
                offer.maker,
                offer.takerAmount
            );
            require(success, "fail to transfer ERC20 token");
        }

        return true;
    }

    /**
     * @dev This function checks the validity of the witness signature.
     * @param offer is the offer which you would like to verify.
     * @param witness is the data that needs to be verified.
     */
    function _checkWitness(
        Offer memory offer,
        bytes memory witness
    ) internal view override {
        bytes32 tokenAddress = abi.decode(
            abi.encode(offer.makerAssetId),
            (bytes32)
        );
        uint256 tokenId = 0; // TODO
        VerifierInterface.Asset[] memory assets = new VerifierInterface.Asset[](
            1
        );
        assets[0] = VerifierInterface.Asset(
            tokenAddress,
            tokenId,
            offer.makerAmount
        );
        bool ok = verifier.verifyAssets(
            assets,
            offer.takerIntmaxAddress,
            witness
        );
        require(ok, "Fail to verify assets");
    }
}
