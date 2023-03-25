// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OfferManagerReverseInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract OfferManagerReverse is OfferManagerReverseInterface {
    /**
     * @dev Struct representing an offer created by a maker and taken by a taker.
     * @param maker is the address of the maker who creates the offer.
     * @param makerIntmaxAddress is the intmax address of the maker.
     * @param makerAssetId is the asset ID that the maker is selling to the taker.
     * @param makerAmount is the amount of the asset that the maker is selling to the taker.
     * @param taker is the address of the taker who takes the offer.
     * @param takerIntmaxAddress is the intmax address of the taker.
     * @param takerTokenAddress is the address of the token that the taker needs to pay.
     * @param takerAmount is the amount of the token that the taker needs to pay.
     * @param isActivated is a boolean flag indicating whether the offer is activated or not.
     */
    struct Offer {
        address maker;
        bytes32 makerIntmaxAddress;
        uint256 makerAssetId;
        uint256 makerAmount;
        address taker;
        bytes32 takerIntmaxAddress;
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

    receive() external payable {}

    function lock(
        bytes32 takerIntmaxAddress,
        address maker,
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount
    ) external payable returns (uint256 offerId) {
        // require(
        //     makerTokenAddress == address(0),
        //     "`makerTokenAddress` only allows zero address (= ETH)"
        // );
        require(
            makerIntmaxAddress != bytes32(0),
            "`makerIntmaxAddress` should not be zero"
        );

        return
            _lock(
                msg.sender, // taker
                takerIntmaxAddress,
                address(0), // ETH
                msg.value, // takerAmount
                maker,
                makerIntmaxAddress,
                makerAssetId,
                makerAmount
            );
    }

    function updateMaker(uint256 offerId, address newMaker) external {
        // The offer must exist.
        require(isLocked(offerId), "This offer ID has not been registered.");

        // Caller must have the permission to update the offer.
        require(
            msg.sender == _offers[offerId].taker,
            "offers can be updated by its taker"
        );

        require(newMaker != address(0), "`newMaker` should not be zero");

        _offers[offerId].maker = newMaker;

        emit UpdateMaker(offerId, newMaker);
    }

    function unlock(
        uint256 offerId,
        bytes memory witness
    ) external returns (bool) {
        Offer memory offer = _offers[offerId];

        // address makerIntmaxAddress = _offers[offerId].makerIntmaxAddress;
        // if (makerIntmaxAddress != address(0)) {
        //     require(
        //         senderIntmax == makerIntmaxAddress,
        //         "offers can be activated by its taker"
        //     );
        // }

        _checkWitness(offer.takerIntmaxAddress, witness);

        // The taker transfers taker's asset to maker.
        require(
            msg.sender == offer.maker,
            "Only maker allows to unlock this offer"
        );
        _unlock(offerId);

        payable(offer.maker).transfer(offer.takerAmount);

        return true;
    }

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

    function isLocked(uint256 offerId) public view returns (bool) {
        return (_offers[offerId].taker != address(0));
    }

    function isUnlocked(uint256 offerId) public view returns (bool) {
        return _offers[offerId].isActivated;
    }

    function _lock(
        address taker,
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        address maker,
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount
    ) internal returns (uint256 offerId) {
        // require(taker != address(0), "The taker must not be zero address.");
        offerId = nextOfferId;
        // require(!isLocked(offerId), "This offer ID is already registered.");

        Offer memory offer = Offer({
            taker: taker,
            takerIntmaxAddress: takerIntmaxAddress,
            takerTokenAddress: takerTokenAddress,
            takerAmount: takerAmount,
            maker: maker,
            makerIntmaxAddress: makerIntmaxAddress,
            makerAssetId: makerAssetId,
            makerAmount: makerAmount,
            isActivated: false
        });

        _isValidOffer(offer);
        _offers[offerId] = offer;
        nextOfferId += 1;
        emit Lock(
            offerId,
            taker,
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            makerIntmaxAddress,
            makerAssetId,
            makerAmount
        );
        emit UpdateMaker(offerId, maker);
    }

    function _unlock(uint256 offerId) internal {
        require(isLocked(offerId), "This offer ID has not been registered.");
        require(!isUnlocked(offerId), "This offer ID is already activated.");
        _offers[offerId].isActivated = true;
        emit Unlock(offerId, _offers[offerId].maker);
    }

    function _checkWitness(
        bytes32 hashed_message,
        bytes memory signature
    ) internal view {
        address signer = ECDSA.recover(hashed_message, signature);
        require(signer == OWNER_ADDRESS, "fail to verify signature");
    }

    function _isValidOffer(Offer memory offer) internal pure {
        require(
            offer.makerAmount <= MAX_REMITTANCE_AMOUNT,
            "invalid offer amount"
        );
    }
}
