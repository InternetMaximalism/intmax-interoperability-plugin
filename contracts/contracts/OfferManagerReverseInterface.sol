// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface OfferManagerReverseInterface {
    /**
     * @notice This event occurs when certain offers are registered.
     * @param offerId is the ID of the offer.
     * @param taker is the taker's account.
     * @param takerIntmaxAddress is the taker's INTMAX account.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     * @param makerIntmaxAddress is the maker's INTMAX account.
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
     * @notice This event occurs when the maker of an offer is updated.
     * @param offerId is the ID of the offer.
     * @param maker is the maker's account.
     */
    event OfferMakerUpdated(uint256 indexed offerId, address indexed maker);

    /**
     * @notice This event occurs when certain offers are activated.
     * @param offerId is the ID of the offer.
     * @param maker is the maker's account.
     */
    event OfferActivated(uint256 indexed offerId, address indexed maker);

    /**
     * @notice Locks the taker's funds and creates a new offer to exchange them for the maker's asset on INTMAX.
     * ATTENTION: This offer cannot be cancelled.
     * @param takerIntmaxAddress is the taker's Intmax address.
     * @param takerAmount is the amount of the token that the taker needs to pay.
     * @param maker is the address of the maker who will receive the taker's funds.
     * @param makerAssetId is the ID of the maker's asset.
     * @param makerAmount is the amount of the maker's asset that the taker will receive.
     * @return offerId is the ID of the newly created offer.
     * @dev This function requires:
     * - The taker must not be the zero address.
     * - The offer ID must not be already registered.
     * - The maker's offer amount must be less than or equal to MAX_REMITTANCE_AMOUNT.
     * This function emits:
     * - An `OfferRegistered` event with the offer details.
     * - An `OfferMakerUpdated` event with the maker's address and offer ID.
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
     * @notice Updates the maker for the specified offer.
     * @param offerId is the ID of the offer to update.
     * @param newMaker is a new maker to assign to the offer.
     * @dev This function requires:
     * - The offer must exist.
     * - The caller must be the taker of the offer.
     * - `newMaker` must not be zero.
     * This function emits:
     * - An `OfferMakerUpdated` event with the new maker's address and offer ID.
     */
    function updateMaker(uint256 offerId, address newMaker) external;

    /**
     * @notice This function accepts an offer and transfers the taker's asset to the maker.
     * @param offerId is the ID of the offer.
     * @param witness is the witness that maker sends asset to taker on INTMAX.
     * @return A boolean indicating whether the offer was successfully unlocked.
     * @dev This function requires:
     * - The offer must exist.
     * - The offer must not be already activated.
     * - Only the maker can activate the offer.
     * - Given witness is valid.
     * This function emits:
     * - An `OfferActivated` event with the offer ID and the maker's address.
     */
    function activate(
        uint256 offerId,
        bytes calldata witness
    ) external returns (bool);
}
