// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OfferManagerInterface.sol";
import "hardhat/console.sol";

contract OfferManager is OfferManagerInterface {
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

    /**
     * @dev This is the ID allocated to the next offer data to be registered.
     */
    uint256 public nextOfferId = 0;

    /**
     * @dev This is the mapping from offer ID to offer data.
     */
    mapping(uint256 => Offer) _offers;

    /**
     * Emits a `OfferRegistered` event with the offer details.
     * Emits an `OfferTakerUpdated` event with the taker's intmax address and offer ID.
     */
    function register(
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount
    ) external returns (uint256 offerId) {
        require(
            _checkTakerTokenAddress(takerTokenAddress),
            "`takerTokenAddress` only allows zero address (= ETH)"
        );
        require(
            _checkTaker(takerIntmaxAddress),
            "`takerIntmaxAddress` must not be zero"
        );

        return
            _register(
                msg.sender, // maker
                makerIntmaxAddress,
                makerAssetId,
                makerAmount,
                taker,
                takerIntmaxAddress,
                takerTokenAddress,
                takerAmount
            );
    }

    /**
     * Emits an `OfferTakerUpdated` event with the new taker's intmax address and offer ID.
     */
    function updateTaker(
        uint256 offerId,
        bytes32 newTakerIntmaxAddress
    ) external {
        // The offer must exist.
        require(
            isRegistered(offerId),
            "This offer ID has not been registered."
        );

        // Caller must have the permission to update the offer.
        require(
            msg.sender == _offers[offerId].maker,
            "offers can be updated by its maker"
        );

        require(
            _checkTaker(newTakerIntmaxAddress),
            "`newTakerIntmaxAddress` should not be zero"
        );

        _offers[offerId].takerIntmaxAddress = newTakerIntmaxAddress;

        emit OfferTakerUpdated(offerId, newTakerIntmaxAddress);
    }

    /**
     * Emits an `OfferActivated` event with the offer ID and the taker's Intmax address.
     */
    function activate(uint256 offerId) external payable returns (bool) {
        address taker = _offers[offerId].taker;
        if (taker != address(0)) {
            require(
                msg.sender == taker,
                "offers can be activated by its taker"
            );
        }

        Offer memory offer = _offers[offerId];

        // The taker transfers his asset to maker.
        require(
            msg.value >= offer.takerAmount,
            "please send enough money to activate"
        );

        _activate(offerId);
        payable(offer.maker).transfer(msg.value);

        return true;
    }

    /**
     * Emits an `OfferDeactivated` event with the offer ID.
     */
    function deactivate(uint256 offerId) external returns (bool) {
        require(
            msg.sender == _offers[offerId].maker,
            "only the maker of an offer can deactivate it"
        );

        _deactivate(offerId);

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

    function isRegistered(uint256 offerId) public view returns (bool) {
        return (_offers[offerId].maker != address(0));
    }

    function isActivated(uint256 offerId) public view returns (bool) {
        return _offers[offerId].isActivated;
    }

    function _register(
        address maker,
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount
    ) internal returns (uint256 offerId) {
        require(maker != address(0), "The maker must not be zero address.");
        offerId = nextOfferId;
        require(!isRegistered(offerId), "This offer ID is already registered.");

        Offer memory offer = Offer({
            maker: maker,
            makerIntmaxAddress: makerIntmaxAddress,
            makerAssetId: makerAssetId,
            makerAmount: makerAmount,
            taker: taker,
            takerIntmaxAddress: takerIntmaxAddress,
            takerTokenAddress: takerTokenAddress,
            takerAmount: takerAmount,
            isActivated: false
        });

        _isValidOffer(offer);
        _offers[offerId] = offer;
        nextOfferId += 1;
        emit OfferRegistered(
            offerId,
            maker,
            makerIntmaxAddress,
            makerAssetId,
            makerAmount,
            taker,
            takerTokenAddress,
            takerAmount
        );
        emit OfferTakerUpdated(offerId, takerIntmaxAddress);
    }

    /**
     * @dev Marks the offer as activated.
     * @param offerId is the ID of the offer.
     */
    function _markOfferAsActivated(uint256 offerId) internal {
        require(
            isRegistered(offerId),
            "This offer ID has not been registered."
        );
        require(!isActivated(offerId), "This offer ID is already activated.");
        _offers[offerId].isActivated = true;
    }

    /**
     * This function activates a offer.
     * @param offerId is the ID of the offer.
     */
    function _activate(uint256 offerId) internal {
        _markOfferAsActivated(offerId);
        emit OfferActivated(offerId, _offers[offerId].takerIntmaxAddress);
    }

    /**
     * This function deactivates a offer.
     * @param offerId is the ID of the offer.
     */
    function _deactivate(uint256 offerId) internal {
        _markOfferAsActivated(offerId);
        emit OfferDeactivated(offerId);
    }

    /**
     * @dev Verify the validity of the offer.
     * @param offer is the offer that needs to be verified.
     *
     * Requirements:
     * - The `makerAmount` in the offer must be less than or equal to `MAX_REMITTANCE_AMOUNT`.
     */
    function _isValidOffer(Offer memory offer) internal pure {
        require(
            offer.makerAmount <= MAX_REMITTANCE_AMOUNT,
            "Invalid offer amount: exceeds maximum remittance amount."
        );
        // require(
        //     offer.makerAmount > 0,
        //     "Maker amount must be greater than zero"
        // );
        // require(
        //     offer.takerAmount > 0,
        //     "Taker amount must be greater than zero"
        // );
    }

    function _checkTaker(bytes32 taker) internal pure returns (bool) {
        // A taker should not be the burn address.
        return taker != bytes32(0);
    }

    function _checkTakerTokenAddress(
        address takerTokenAddress
    ) internal pure virtual returns (bool) {
        // TODO: should allow ERC20
        return takerTokenAddress == address(0);
    }
}
