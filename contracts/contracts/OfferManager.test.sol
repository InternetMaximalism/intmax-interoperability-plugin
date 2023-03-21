// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OfferManager.sol";

contract OfferManagerTest is OfferManager {
    /**
     * This function registers a new offer.
     * @param makerAssetId is the asset ID a maker sell to taker.
     * @param makerAmount is the amount a maker sell to taker.
     * @param taker is the taker's account.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     */
    function testRegister(
        bytes32 makerIntmax,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmax,
        address takerTokenAddress,
        uint256 takerAmount
    ) external returns (uint256 flagId) {
        return
            _register(
                msg.sender,
                makerIntmax,
                makerAssetId,
                makerAmount,
                taker,
                takerIntmax,
                takerTokenAddress,
                takerAmount
            );
    }

    /**
     * This test function can activate the flag without actually making the transfer.
     * @param offerId is the ID of the offer.
     */
    function testActivate(uint256 offerId) external returns (bool) {
        _activate(offerId);

        return true;
    }
}
