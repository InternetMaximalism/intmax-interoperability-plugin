// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerInterface.sol";
import "./OfferManagerBase.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract OfferManager is
    OfferManagerInterface,
    OfferManagerBase,
    ContextUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    function initialize() public initializer {
        __Context_init();
    }

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
        // Check if given `takerTokenAddress` is either ETH or ERC20.
        if (takerTokenAddress != address(0)) {
            uint256 totalSupply = IERC20(takerTokenAddress).totalSupply();
            require(
                totalSupply != 0,
                "the total supply of ERC20 must not be zero"
            );
        }

        return
            _register(
                _msgSender(), // maker
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
            _msgSender() == _offers[offerId].maker,
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
                _msgSender() == taker,
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
        if (offer.takerTokenAddress == address(0)) {
            payable(offer.maker).transfer(msg.value);
        } else {
            require(
                msg.value == 0,
                "transmission method other than ETH is specified"
            );
            bool success = IERC20(offer.takerTokenAddress).transferFrom(
                _msgSender(),
                offer.maker,
                offer.takerAmount
            );
            require(success, "fail to transfer ERC20 token");
        }

        return true;
    }

    /**
     * Emits an `OfferDeactivated` event with the offer ID.
     */
    function deactivate(uint256 offerId) external returns (bool) {
        require(
            _msgSender() == _offers[offerId].maker,
            "only the maker of an offer can deactivate it"
        );

        _deactivate(offerId);

        return true;
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
        offerId = _nextOfferId.current();
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
        _nextOfferId.increment();
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
}
