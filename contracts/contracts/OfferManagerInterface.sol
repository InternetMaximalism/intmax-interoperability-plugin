// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface OfferManagerInterface {
    /**
     * This event occurs when certain offers are registered.
     * @param offerId is the ID of the offer.
     * @param maker is the maker's account.
     * @param makerIntmax is the maker's intmax account.
     * @param makerAssetId is the asset ID a maker sell to taker.
     * @param makerAmount is the amount a maker sell to taker.
     * @param taker is the taker's account.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     */
    event Register(
        uint256 indexed offerId,
        address indexed maker,
        bytes32 makerIntmax,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        address takerTokenAddress,
        uint256 takerAmount
    );

    /**
     * @param offerId is the ID of the offer.
     * @param takerIntmax is the taker's intmax account.
     */
    event UpdateTaker(uint256 indexed offerId, bytes32 indexed takerIntmax);

    /**
     * This event occurs when certain offers are activated.
     * @param offerId is the ID of the offer.
     * @param takerIntmax is the taker's intmax account.
     */
    event Activate(uint256 indexed offerId, bytes32 indexed takerIntmax);

    event Deactivate(uint256 indexed offerId);

    /**
     * This function registers a new offer.
     * @param makerIntmax is the maker's intmax account.
     * @param makerAssetId is the asset ID a maker sell to taker.
     * @param makerAmount is the amount a maker sell to taker.
     * @param taker is the taker's account.
     * @param takerIntmax is the taker's intmax account.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     */
    function register(
        bytes32 makerIntmax,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmax,
        address takerTokenAddress,
        uint256 takerAmount
    ) external returns (uint256 flagId);

    function updateTaker(uint256 offerId, bytes32 newTaker) external;

    /**
     * This function activate a offer in exchange for payment.
     * @param offerId is the ID of the offer.
     */
    function activate(uint256 offerId) external payable returns (bool);

    /**
     * This function deactivate a offer.
     * Offers can be deactivated by its maker.
     * @param offerId is the ID of the offer.
     */
    function deactivate(uint256 offerId) external returns (bool);

    function getOffer(
        uint256 offerId
    )
        external
        view
        returns (
            address maker,
            bytes32 makerIntmax,
            uint256 makerAssetId,
            uint256 makerAmount,
            address taker,
            bytes32 takerIntmax,
            address takerTokenAddress,
            uint256 takerAmount,
            bool activated
        );

    function isRegistered(uint256 offerId) external view returns (bool);

    function isActivated(uint256 offerId) external view returns (bool);
}
