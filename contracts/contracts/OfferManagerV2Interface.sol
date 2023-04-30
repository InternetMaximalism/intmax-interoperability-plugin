// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerInterface.sol";

interface OfferManagerV2Interface is OfferManagerInterface {
    /**
     * @notice This function registers a new offer.
     * @param makerIntmaxAddress is the maker's INTMAX address.
     * @param makerAssetId is the asset ID that the maker is selling to the taker.
     * @param makerAmount is the amount of asset that the maker is selling to the taker.
     * @param taker is the taker's address.
     * @param takerIntmaxAddress is the taker's INTMAX address.
     * @param takerTokenAddress is the token address that the taker should pay to the maker.
     * @param takerAmount is the amount of token that the taker should pay to the maker.
     * @param witness is the witness that maker burned his assets.
     * @return offerId is the ID of the newly registered offer.
     * @dev This function requires:
     * - `takerTokenAddress` must be a valid address.
     * - `takerIntmax` must not be zero.
     * - The caller must not be a zero address.
     * - The offer ID must not be already registered.
     * - The offer must be valid.
     * - Given witness is valid.
     * This function emits:
     * - An `OfferRegistered` event with the offer details.
     * - An `OfferTakerUpdated` event with the taker's INTMAX address and offer ID.
     */
    function register(
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        bytes memory witness
    ) external returns (uint256 offerId);
}
