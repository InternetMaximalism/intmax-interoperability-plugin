// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface OfferManagerInterface {
    /**
     * This event occurs when certain offers are registered.
     * @param offerId is the ID of the offer.
     * @param maker is the maker's account.
     * @param taker is the taker's account.
     * @param makerAssetId is the asset ID a maker sell to taker.
     * @param makerAmount is the amount a maker sell to taker.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     */
    event Register(
        uint256 indexed offerId,
        address indexed maker,
        bytes32 indexed taker,
        uint256 makerAssetId,
        uint256 makerAmount,
        address takerTokenAddress,
        uint256 takerAmount
    );

    /**
     * This event occurs when certain offers are activated.
     * @param offerId is the ID of the offer.
     */
    event Activate(uint256 indexed offerId);

    event Deactivate(uint256 indexed offerId);

    /**
     * This function registers a new offer.
     * @param makerAssetId is the asset ID a maker sell to taker.
     * @param makerAmount is the amount a maker sell to taker.
     * @param taker is the taker's account.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     * TODO: proof is the witness that maker's asset was sent to the burn address.
     */
    function register(
        uint256 makerAssetId,
        uint256 makerAmount,
        bytes32 taker,
        address takerTokenAddress,
        uint256 takerAmount
    ) external returns (uint256 flagId);

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

    function isRegistered(uint256 offerId) external view returns (bool);

    function isActivated(uint256 offerId) external view returns (bool);
}
