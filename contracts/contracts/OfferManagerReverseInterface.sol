// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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
    event Lock(
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
     * @param offerId is the ID of the offer.
     * @param maker is the maker's account.
     */
    event UpdateMaker(uint256 indexed offerId, address indexed maker);

    /**
     * This event occurs when certain offers are activated.
     * @param offerId is the ID of the offer.
     */
    event Unlock(uint256 indexed offerId, address maker);

    /**
     * @dev This function locks its own token and requests the token held by the counterparty on intmax.
     * @param makerIntmaxAddress is the account that wants to receive assets on intmax.
     * @param taker is the destination account to send on this chain.
     * @param takerIntmaxAddress is the account (or anyone in the case of zero) you want to send assets to on intmax.
     * @param takerAssetId is the asset you want sent on intmax.
     * @param takerAmount is the amount of assets you want sent on intmax.
     */
    function lock(
        bytes32 makerIntmaxAddress,
        address taker,
        bytes32 takerIntmaxAddress,
        uint256 takerAssetId,
        uint256 takerAmount
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
     * @dev This function unlocks the locked token when a transaction is accepted on intmax.
     * @param offerId is the ID of the offer.
     * @param witness is the witness that maker sends asset to taker on intmax.
     */
    function unlock(
        uint256 offerId,
        bytes memory witness
    ) external returns (bool);

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

    function isLocked(uint256 offerId) external view returns (bool);

    function isUnlocked(uint256 offerId) external view returns (bool);
}
