// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerBaseInterface.sol";

interface OfferManagerInterface {
    /**
     * @notice This event occurs when certain offers are registered.
     * @param offerId is the ID of the offer.
     * @param maker is the maker's account.
     * @param makerIntmaxAddress is the maker's INTMAX account.
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
     * @notice This event occurs when the taker of an offer is updated.
     * @param offerId is the ID of the offer.
     * @param takerIntmaxAddress is the taker's INTMAX account.
     */
    event OfferTakerUpdated(
        uint256 indexed offerId,
        bytes32 indexed takerIntmaxAddress
    );

    /**
     * @notice This event occurs when certain offers are activated.
     * @param offerId is the ID of the offer.
     * @param takerIntmaxAddress is the taker's INTMAX address.
     */
    event OfferActivated(
        uint256 indexed offerId,
        bytes32 indexed takerIntmaxAddress
    );

    /**
     * @notice This event occurs when an offer is deactivated.
     * @param offerId is the ID of the offer.
     */
    event OfferDeactivated(uint256 indexed offerId);

    /**
     * @notice This function registers a new offer.
     * @param makerIntmaxAddress is the maker's INTMAX address.
     * @param makerAssetId is the asset ID that the maker is selling to the taker.
     * @param makerAmount is the amount of asset that the maker is selling to the taker.
     * @param taker is the taker's address.
     * @param takerIntmaxAddress is the taker's INTMAX address.
     * @param takerTokenAddress is the token address that the taker should pay to the maker.
     * @param takerAmount is the amount of token that the taker should pay to the maker.
     * @return offerId is the ID of the newly registered offer.
     * @dev This function requires:
     * - `takerTokenAddress` must be a valid address.
     * - `takerIntmax` must not be zero.
     * - The caller must not be a zero address.
     * - The offer ID must not be already registered.
     * - The offer must be valid.
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
        uint256 takerAmount
    ) external returns (uint256 offerId);

    /**
     * @notice This function updates the taker of an existing offer.
     * @param offerId is the ID of the offer to be updated.
     * @param newTakerIntmaxAddress is the new taker's INTMAX address.
     * @dev This function requires:
     * - The offer must exist.
     * - The caller must be the maker of the offer.
     * - `newTakerIntmaxAddress` must not be zero.
     * This function emits:
     * - An `OfferTakerUpdated` event with the new taker's INTMAX address and offer ID.
     */
    function updateTaker(
        uint256 offerId,
        bytes32 newTakerIntmaxAddress
    ) external;

    /**
     * @notice This function activates an offer by transferring the taker's asset to the maker in exchange for payment.
     * @param offerId is the ID of the offer to activate.
     * @return A boolean indicating whether the offer is successfully activated.
     * @dev This function requires:
     * - The offer must exist.
     * - The offer must not be already activated.
     * - Only the taker can activate it if the taker is specified.
     * - The payment must be equal to or greater than the taker's asset amount.
     * This function emits:
     * - An `OfferActivated` event with the offer ID and the taker's INTMAX address.
     */
    function activate(uint256 offerId) external payable returns (bool);

    /**
     * @notice This function deactivates an offer, preventing it from being activated in the future.
     * @param offerId is the ID of the offer to be deactivated.
     * @return A boolean indicating whether the deactivation was successful.
     * @dev This function is equivalent to the `activate()` function when `takerIntmaxAddress == makerIntmaxAddress`.
     * This function requires:
     * - The offer must exist.
     * - The offer must not be already activated.
     * - Only the maker can deactivate it.
     * This function emits:
     * - An `OfferActivated` event with the offer ID and the maker's INTMAX address.
     */
    function deactivate(uint256 offerId) external returns (bool);
}
