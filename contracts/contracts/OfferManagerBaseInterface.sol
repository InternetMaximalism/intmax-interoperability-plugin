// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface OfferManagerBaseInterface {
    /**
     * @dev Struct representing an offer created by a maker and taken by a taker.
     * @param maker is the address of the maker who creates the offer.
     * @param makerIntmaxAddress is the intmax address of the maker.
     * @param makerAssetId is the asset ID that the maker is selling to the taker.
     * @param makerAmount is the amount of the asset that the maker is selling to the taker.
     * @param taker is the address of the taker who takes the offer.
     * @param takerIntmaxAddress is the intmax address of the taker.
     * @param takerTokenAddress is the address of the token that the taker needs to pay.
     * @param takerAmount is the amount of the token that the taker needs to pay.
     * @param isActivated is a boolean flag indicating whether the offer is activated or not.
     */
    struct Offer {
        address maker;
        bytes32 makerIntmaxAddress;
        uint256 makerAssetId;
        uint256 makerAmount;
        address taker;
        bytes32 takerIntmaxAddress;
        address takerTokenAddress;
        uint256 takerAmount;
        bool isActivated;
    }

    function nextOfferId() external view returns (uint256);

    function getOffer(
        uint256 offerId
    )
        external
        view
        returns (
            address maker,
            bytes32 makerIntmaxAddress,
            uint256 makerAssetId,
            uint256 makerAmount,
            address taker,
            bytes32 takerIntmaxAddress,
            address takerTokenAddress,
            uint256 takerAmount,
            bool activated
        );

    function isRegistered(uint256 offerId) external view returns (bool);

    function isActivated(uint256 offerId) external view returns (bool);
}
