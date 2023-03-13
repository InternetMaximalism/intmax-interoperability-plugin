// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract OfferManager {
    struct Offer {
        address maker;
        uint256 makerAssetId;
        uint256 makerAmount;
        bytes32 taker;
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
    mapping(uint256 => Offer) offers;

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

    /**
     * This function registers a new offer.
     * @param maker is the maker's account.
     * @param makerAssetId is the asset ID a maker sell to taker.
     * @param makerAmount is the amount a maker sell to taker.
     * @param taker is the taker's account.
     * @param takerTokenAddress is the token address a taker should pay.
     * @param takerAmount is the amount a taker should pay.
     */
    function register(
        address maker,
        uint256 makerAssetId,
        uint256 makerAmount,
        bytes32 taker,
        address takerTokenAddress,
        uint256 takerAmount
    ) external returns (uint256 flagId) {
        // TODO: Ensure the maker's asset has been transfered to zero address.

        require(_checkTakerTokenAddress(takerTokenAddress));

        return
            _register(
                maker,
                makerAssetId,
                makerAmount,
                taker,
                takerTokenAddress,
                takerAmount
            );
    }

    function activate(uint256 offerId) external payable returns (bool) {
        Offer memory offer = offers[offerId];

        address payable maker = payable(offer.maker);

        // The taker transfers taker's asset to maker.
        require(_checkTakerTokenAddress(offer.takerTokenAddress));
        bool res = maker.send(msg.value);
        require(res, "failed to send Ether");

        _activate(offerId);

        return true;
    }

    function isRegistered(uint256 offerId) public view returns (bool) {
        return (offers[offerId].maker != address(0));
    }

    function isActivated(uint256 offerId) public view returns (bool) {
        return offers[offerId].isActivated;
    }

    /**
     * This function registers a new offer.
     */
    function _register(
        address maker,
        uint256 makerAssetId,
        uint256 makerAmount,
        bytes32 taker,
        address takerTokenAddress,
        uint256 takerAmount
    ) internal returns (uint256 offerId) {
        require(maker != address(0), "The maker must not be zero address.");
        offerId = nextOfferId;
        require(!isRegistered(offerId), "This offer ID is already registered.");

        Offer memory offer = Offer({
            maker: maker,
            makerAssetId: makerAssetId,
            makerAmount: makerAmount,
            taker: taker,
            takerTokenAddress: takerTokenAddress,
            takerAmount: takerAmount,
            isActivated: false
        });

        _isValidOffer(offer);
        offers[offerId] = offer;
        nextOfferId += 1;
        emit Register(
            offerId,
            maker,
            taker,
            makerAssetId,
            makerAmount,
            takerTokenAddress,
            takerAmount
        );
    }

    /**
     * This function activates a offer.
     * @param offerId is the ID of the offer.
     */
    function _activate(uint256 offerId) internal {
        require(
            isRegistered(offerId),
            "This offer ID has not been registered."
        );
        require(!isActivated(offerId), "This offer ID is already activated.");
        offers[offerId].isActivated = true;
        emit Activate(offerId);
    }

    function _isValidOffer(Offer memory offer) internal pure {
        // require(offer.makerAssetId <= MAX_ASSET_ID, "invalid asset ID");
        require(
            offer.makerAmount <= MAX_REMITTANCE_AMOUNT,
            "invalid offer amount"
        );
    }

    function _checkTakerTokenAddress(
        address takerTokenAddress
    ) internal pure returns (bool) {
        // TODO: should allow ERC20
        return takerTokenAddress == address(0);
    }
}
