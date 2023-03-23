// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OfferManagerReverseInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract OfferManagerReverse is OfferManagerReverseInterface {
    struct Offer {
        address maker;
        bytes32 makerIntmax;
        uint256 makerAssetId;
        uint256 makerAmount;
        address taker;
        bytes32 takerIntmax;
        address takerTokenAddress;
        uint256 takerAmount;
        bool isActivated;
    }

    // uint256 constant MAX_ASSET_ID = 18446744069414584320; // the maximum value of Goldilocks field
    uint256 constant MAX_REMITTANCE_AMOUNT = 18446744069414584320; // the maximum value of Goldilocks field
    address immutable OWNER_ADDRESS;

    /**
     * @dev This is the ID allocated to the next offer data to be registered.
     */
    uint256 public nextOfferId = 0;

    /**
     * @dev This is the mapping from offer ID to offer data.
     */
    mapping(uint256 => Offer) _offers;

    constructor() {
        OWNER_ADDRESS = msg.sender;
    }

    /**
     *
     * @param takerIntmax is intmax 上で asset を受け取りたいアカウント
     * @param maker is このチェーン上で送る宛先アカウント
     * @param makerIntmax is intmax 上で asset を送ってほしいアカウント (zero の場合は誰でも)
     * @param makerAssetId is intmax 上で送ってほしい asset
     * @param makerAmount is intmax 上で送ってほしい asset の量
     */
    function lock(
        bytes32 takerIntmax,
        address maker,
        bytes32 makerIntmax,
        uint256 makerAssetId,
        uint256 makerAmount
    ) external payable returns (uint256 offerId) {
        // require(
        //     makerTokenAddress == address(0),
        //     "`makerTokenAddress` only allows zero address (= ETH)"
        // );
        require(makerIntmax != bytes32(0), "`makerIntmax` should not be zero");

        return
            _lock(
                msg.sender,
                takerIntmax,
                address(0), // ETH
                msg.value,
                maker,
                makerIntmax,
                makerAssetId,
                makerAmount
            );
    }

    function _lock(
        address taker,
        bytes32 takerIntmax,
        address takerTokenAddress,
        uint256 takerAmount,
        address maker,
        bytes32 makerIntmax,
        uint256 makerAssetId,
        uint256 makerAmount
    ) internal returns (uint256 offerId) {
        require(taker != address(0), "The taker must not be zero address.");
        offerId = nextOfferId;
        require(!isLocked(offerId), "This offer ID is already registered.");

        Offer memory offer = Offer({
            taker: taker,
            takerIntmax: takerIntmax,
            takerTokenAddress: takerTokenAddress,
            takerAmount: takerAmount,
            maker: maker,
            makerIntmax: makerIntmax,
            makerAssetId: makerAssetId,
            makerAmount: makerAmount,
            isActivated: false
        });

        _isValidOffer(offer);
        _offers[offerId] = offer;
        nextOfferId += 1;
    }

    function updateTaker(uint256 offerId, address newMaker) external {
        require(
            msg.sender == _offers[offerId].taker,
            "offers can be updated by its taker"
        );
        require(newMaker != address(0), "`newMaker` should not be zero");

        _offers[offerId].maker = newMaker;

        // emit UpdateTaker(offerId, newTakerIntmax);
    }

    /**
     * This function activate a offer in exchange for payment.
     * @param offerId is the ID of the offer.
     * @param witness is the witness that maker sends asset to taker on intmax.
     */
    function unlock(
        uint256 offerId,
        bytes memory witness
    ) external returns (bool) {
        Offer memory offer = _offers[offerId];

        // address makerIntmax = _offers[offerId].makerIntmax;
        // if (makerIntmax != address(0)) {
        //     require(
        //         senderIntmax == makerIntmax,
        //         "offers can be activated by its taker"
        //     );
        // }

        _checkWitness(offer.takerIntmax, witness);

        // The taker transfers taker's asset to maker.
        require(msg.sender == offer.maker);
        payable(offer.taker).transfer(offer.makerAmount);

        require(isLocked(offerId), "This offer ID has not been registered.");
        require(!isUnlocked(offerId), "This offer ID is already activated.");
        offer.isActivated = true;

        return true;
    }

    function _checkWitness(
        bytes32 hashed_message,
        bytes memory signature
    ) internal view {
        address signer = ECDSA.recover(hashed_message, signature);
        require(signer == OWNER_ADDRESS);
    }

    function getOffer(
        uint256 offerId
    )
        public
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
        )
    {
        Offer storage offer = _offers[offerId];
        maker = offer.maker;
        makerIntmax = offer.makerIntmax;
        makerAssetId = offer.makerAssetId;
        makerAmount = offer.makerAmount;
        taker = offer.taker;
        takerIntmax = offer.takerIntmax;
        takerTokenAddress = offer.takerTokenAddress;
        takerAmount = offer.takerAmount;
        activated = offer.isActivated;
    }

    function isLocked(uint256 offerId) public view returns (bool) {
        return (_offers[offerId].maker != address(0));
    }

    function isUnlocked(uint256 offerId) public view returns (bool) {
        return _offers[offerId].isActivated;
    }

    function _isValidOffer(Offer memory offer) internal pure {
        // require(offer.makerAssetId <= MAX_ASSET_ID, "invalid asset ID");
        require(
            offer.makerAmount <= MAX_REMITTANCE_AMOUNT,
            "invalid offer amount"
        );
    }
}
