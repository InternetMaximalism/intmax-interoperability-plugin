// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface OfferManagerReverseInterface {
    /**
     * This event occurs when certain offers are registered.
     * @param offerId is the ID of the offer.
     * @param taker is the taker's account.
     * @param takerIntmaxAddress is the taker's intmax account.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     * @param makerIntmaxAddress is the maker's intmax account.
     * @param makerAssetId is the asset ID a maker sell to taker.
     * @param makerAmount is the amount a maker sell to taker.
     */
    event OfferRegistered(
        uint256 indexed offerId,
        address indexed taker,
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount
    );

    /**
     * This event occurs when the maker of an offer is updated.
     * @param offerId is the ID of the offer.
     * @param maker is the maker's account.
     */
    event OfferMakerUpdated(uint256 indexed offerId, address indexed maker);

    /**
     * This event occurs when certain offers are activated.
     * @param offerId is the ID of the offer.
     * @param maker is the maker's account.
     */
    event OfferActivated(uint256 indexed offerId, address indexed maker);

    /**
     * @dev Locks the taker's funds and creates a new offer to exchange them for the maker's asset on intmax.
     * @param takerIntmaxAddress is the taker's Intmax address.
     * @param takerAmount is the amount of the token that the taker needs to pay.
     * @param maker is the address of the maker who will receive the taker's funds.
     * @param makerAssetId is the ID of the maker's asset.
     * @param makerAmount is the amount of the maker's asset that the taker will receive.
     * @return offerId is the ID of the newly created offer.
     */
    function register(
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        address maker,
        uint256 makerAssetId,
        uint256 makerAmount
    ) external payable returns (uint256 offerId);

    /**
     * @dev Updates the maker for the specified offer.
     * @param offerId is the ID of the offer to update.
     * @param newMaker is a new maker to assign to the offer.
     *
     * Requirements:
     * - The offer must exist.
     * - Caller must have the permission to update the offer.
     */
    function updateMaker(uint256 offerId, address newMaker) external;

    /**
     * @dev This function accepts an offer and transfers the taker's asset to the maker.
     * @param offerId is the ID of the offer.
     * @param witness is the witness that maker sends asset to taker on intmax.
     * @return A boolean indicating whether the offer was successfully unlocked.
     *
     * Requirements:
     * - The offer must exist.
     */
    function activate(
        uint256 offerId,
        bytes calldata witness
    ) external returns (bool);
}
