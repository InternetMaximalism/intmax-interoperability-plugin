// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OfferManagerInterface.sol";
import "hardhat/console.sol";

contract OfferManager is OfferManagerInterface {
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

    /**
     * @dev This is the ID allocated to the next offer data to be registered.
     */
    uint256 public nextOfferId = 0;

    /**
     * @dev This is the mapping from offer ID to offer data.
     */
    mapping(uint256 => Offer) _offers;

    function register(
        bytes32 makerIntmax,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmax,
        address takerTokenAddress,
        uint256 takerAmount
    ) external returns (uint256 offerId) {
        require(
            _checkTakerTokenAddress(takerTokenAddress),
            "`takerTokenAddress` only allows zero address (= ETH)"
        );
        require(_checkTaker(takerIntmax), "`takerIntmax` should not be zero");

        return
            _register(
                msg.sender, // maker
                makerIntmax,
                makerAssetId,
                makerAmount,
                taker,
                takerIntmax,
                takerTokenAddress,
                takerAmount
            );
    }

    function updateTaker(uint256 offerId, bytes32 newTakerIntmax) external {
        require(
            msg.sender == _offers[offerId].maker,
            "offers can be updated by its maker"
        );
        require(_checkTaker(newTakerIntmax), "`newTaker` should not be zero");

        _offers[offerId].takerIntmax = newTakerIntmax;

        emit UpdateTaker(offerId, newTakerIntmax);
    }

    /**
     * This function activate a offer in exchange for payment.
     * @param offerId is the ID of the offer.
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

        // The taker transfers taker's asset to maker.
        require(
            msg.value >= offer.takerAmount,
            "please send enough money to activate"
        );
        payable(offer.maker).transfer(msg.value);

        _activate(offerId);

        return true;
    }

    /**
     * This function deactivate a offer.
     * Offers can be deactivated by its maker.
     * @param offerId is the ID of the offer.
     */
    function deactivate(uint256 offerId) external returns (bool) {
        require(
            msg.sender == _offers[offerId].maker,
            "offers can be deactivated by its maker"
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

    function isRegistered(uint256 offerId) public view returns (bool) {
        return (_offers[offerId].maker != address(0));
    }

    function isActivated(uint256 offerId) public view returns (bool) {
        return _offers[offerId].isActivated;
    }

    /**
     * This function registers a new offer.
     */
    function _register(
        address maker,
        bytes32 makerIntmax,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmax,
        address takerTokenAddress,
        uint256 takerAmount
    ) internal returns (uint256 offerId) {
        require(maker != address(0), "The maker must not be zero address.");
        offerId = nextOfferId;
        require(!isRegistered(offerId), "This offer ID is already registered.");

        Offer memory offer = Offer({
            maker: maker,
            makerIntmax: makerIntmax,
            makerAssetId: makerAssetId,
            makerAmount: makerAmount,
            taker: taker,
            takerIntmax: takerIntmax,
            takerTokenAddress: takerTokenAddress,
            takerAmount: takerAmount,
            isActivated: false
        });

        _isValidOffer(offer);
        _offers[offerId] = offer;
        nextOfferId += 1;
        emit Register(
            offerId,
            maker,
            makerIntmax,
            makerAssetId,
            makerAmount,
            taker,
            takerTokenAddress,
            takerAmount
        );
        emit UpdateTaker(offerId, takerIntmax);
    }

    /**
     * This function completes a offer.
     * @param offerId is the ID of the offer.
     */
    function _completeOffer(uint256 offerId) internal {
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
        _completeOffer(offerId);
        emit Activate(offerId, _offers[offerId].takerIntmax);
    }

    /**
     * This function deactivates a offer.
     * @param offerId is the ID of the offer.
     */
    function _deactivate(uint256 offerId) internal {
        _completeOffer(offerId);
        emit Deactivate(offerId);
    }

    function _isValidOffer(Offer memory offer) internal pure {
        // require(offer.makerAssetId <= MAX_ASSET_ID, "invalid asset ID");
        require(
            offer.makerAmount <= MAX_REMITTANCE_AMOUNT,
            "invalid offer amount"
        );
    }

    function _checkTaker(bytes32 taker) internal pure returns (bool) {
        // A taker should not be the burn address.
        return taker != bytes32(0);
    }

    function _checkTakerTokenAddress(
        address takerTokenAddress
    ) internal pure returns (bool) {
        // TODO: should allow ERC20
        return takerTokenAddress == address(0);
    }
}
