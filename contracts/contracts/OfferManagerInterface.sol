// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerBaseInterface.sol";

interface OfferManagerInterface {
    /**
     * This event occurs when certain offers are registered.
     * @param offerId is the ID of the offer.
     * @param maker is the maker's account.
     * @param makerIntmaxAddress is the maker's intmax account.
     * @param makerAssetId is the asset ID a maker sell to taker.
     * @param makerAmount is the amount a maker sell to taker.
     * @param taker is the taker's account.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     */
    event OfferRegistered(
        uint256 indexed offerId,
        address indexed maker,
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        address takerTokenAddress,
        uint256 takerAmount
    );

    /**
     * This event occurs when the taker of an offer is updated.
     * @param offerId is the ID of the offer.
     * @param takerIntmaxAddress is the taker's intmax account.
     */
    event OfferTakerUpdated(
        uint256 indexed offerId,
        bytes32 indexed takerIntmaxAddress
    );

    /**
     * This event occurs when certain offers are activated.
     * @param offerId is the ID of the offer.
     * @param takerIntmaxAddress is the taker's intmax address.
     */
    event OfferActivated(
        uint256 indexed offerId,
        bytes32 indexed takerIntmaxAddress
    );

    /**
     * This event occurs when an offer is deactivated.
     * @param offerId is the ID of the offer.
     */
    event OfferDeactivated(uint256 indexed offerId);

    /**
     * @dev Registers a new offer.
     * @param makerIntmaxAddress is the maker's intmax address.
     * @param makerAssetId is the asset ID that the maker is selling to the taker.
     * @param makerAmount is the amount of asset that the maker is selling to the taker.
     * @param taker is the taker's address.
     * @param takerIntmaxAddress is the taker's intmax address.
     * @param takerTokenAddress is the token address that the taker should pay to the maker.
     * @param takerAmount is the amount of token that the taker should pay to the maker.
     * @return offerId is the ID of the newly registered offer.
     *
     * Requirements:
     * - `takerTokenAddress` must be a valid address.
     * - `takerIntmax` must not be zero.
     * - The caller must not be a zero address.
     * - The offer ID must not be already registered.
     * - The offer must be valid.
     */
    function register(
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount
    ) external returns (uint256 offerId);

    /**
     * @dev Updates the taker of an existing offer.
     * @param offerId is the ID of the offer to be updated.
     * @param newTakerIntmaxAddress is the new taker's intmax address.
     *
     * Requirements:
     * - The offer must exist.
     * - The caller must be the maker of the offer.
     * - `newTakerIntmaxAddress` must not be zero.
     */
    function updateTaker(
        uint256 offerId,
        bytes32 newTakerIntmaxAddress
    ) external;

    /**
     * @dev Activate an offer by transferring the taker's asset to the maker in exchange for payment.
     * @param offerId is the ID of the offer to activate.
     * @return A boolean indicating whether the offer is successfully activated.
     *
     * Requirements:
     * - The offer must exist.
     * - The offer must not be already activated.
     * - If the offer has a taker, only the taker can activate it.
     * - The payment must be equal to or greater than the taker's asset amount.
     */
    function activate(uint256 offerId) external payable returns (bool);

    /**
     * Deactivates an offer, preventing it from being activated in the future.
     * @param offerId is the ID of the offer to be deactivated.
     * @return A boolean indicating whether the deactivation was successful.
     */
    function deactivate(uint256 offerId) external returns (bool);
}
