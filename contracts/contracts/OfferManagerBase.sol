// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerBaseInterface.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

abstract contract OfferManagerBase is OfferManagerBaseInterface {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * @dev This constant represents the amount of tokens that can be transferred at one time on INTMAX.
     */
    uint256 constant MAX_REMITTANCE_AMOUNT = 18446744069414584320; // the maximum value of Goldilocks field

    /**
     * @dev This is the ID allocated to the next offer data to be registered.
     */
    CountersUpgradeable.Counter _nextOfferId;

    /**
     * @dev This is the mapping from offer ID to offer data.
     */
    mapping(uint256 => Offer) _offers;

    // この関数は戻り値をstructのままにした方がシンプルになるのではと思うのですが、どうでしょうか。
    function getOffer(
        uint256 offerId
    )
        public
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
        )
    {
        Offer storage offer = _offers[offerId];
        maker = offer.maker;
        makerIntmaxAddress = offer.makerIntmaxAddress;
        makerAssetId = offer.makerAssetId;
        makerAmount = offer.makerAmount;
        taker = offer.taker;
        takerIntmaxAddress = offer.takerIntmaxAddress;
        takerTokenAddress = offer.takerTokenAddress;
        takerAmount = offer.takerAmount;
        activated = offer.isActivated;
    }

    function nextOfferId() public view returns (uint256 offerId) {
        return _nextOfferId.current();
    }
}
