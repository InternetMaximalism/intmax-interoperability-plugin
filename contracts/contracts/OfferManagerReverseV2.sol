// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerReverse.sol";
import "./VerifierInterface.sol";

contract OfferManagerReverseV2 is OfferManagerReverse {
    VerifierInterface verifier;

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

        _checkWitness(offer, witness);

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
     * @dev Verify the validity of the witness signature.
     * @param offer is the offer which you would like to verify.
     * @param witness is the data that needs to be verified.
     */
    function _checkWitness(
        Offer memory offer,
        bytes memory witness
    ) internal view override {
        // bytes32 networkIndex = verifier.networkIndex();
        bytes32 tokenAddress = abi.decode(
            abi.encode(offer.makerAssetId),
            (bytes32)
        );
        uint256 tokenId = 0; // TODO
        VerifierInterface.Asset memory asset = VerifierInterface.Asset(
            offer.takerIntmaxAddress,
            tokenAddress,
            tokenId,
            offer.makerAmount
        );
        verifier.verifyAsset(asset, witness);
    }
}
