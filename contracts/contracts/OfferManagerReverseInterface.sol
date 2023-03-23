// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface OfferManagerReverseInterface {
    /**
     * This event occurs when certain offers are registered.
     * @param offerId is the ID of the offer.
     * @param taker is the taker's account.
     * @param takerIntmax is the taker's intmax account.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     * @param makerIntmax is the maker's intmax account.
     * @param makerAssetId is the asset ID a maker sell to taker.
     * @param makerAmount is the amount a maker sell to taker.
     */
    event Lock(
        uint256 indexed offerId,
        address indexed taker,
        bytes32 takerIntmax,
        address takerTokenAddress,
        uint256 takerAmount,
        bytes32 makerIntmax,
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
     *
     * @param makerIntmax is intmax 上で asset を受け取りたいアカウント
     * @param taker is このチェーン上で送る宛先アカウント
     * @param takerIntmax is intmax 上で asset を送ってほしいアカウント (zero の場合は誰でも)
     * @param takerAssetId is intmax 上で送ってほしい asset
     * @param takerAmount is intmax 上で送ってほしい asset の量
     */
    function lock(
        bytes32 makerIntmax,
        address taker,
        bytes32 takerIntmax,
        uint256 takerAssetId,
        uint256 takerAmount
    ) external payable returns (uint256 offerId);

    /**
     * This function updates taker.
     * @param offerId is the ID of the offer.
     * @param newMaker is a new maker.
     */
    function updateMaker(uint256 offerId, address newMaker) external;

    /**
     * This function activate a offer in exchange for payment.
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
            bytes32 makerIntmax,
            uint256 makerAssetId,
            uint256 makerAmount,
            address taker,
            bytes32 takerIntmax,
            address takerTokenAddress,
            uint256 takerAmount,
            bool activated
        );

    function isLocked(uint256 offerId) external view returns (bool);

    function isUnlocked(uint256 offerId) external view returns (bool);
}
