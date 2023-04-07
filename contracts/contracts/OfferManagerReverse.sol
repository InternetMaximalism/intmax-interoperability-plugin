// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerReverseInterface.sol";
import "./OfferManagerBase.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OfferManagerReverse is
    OfferManagerReverseInterface,
    OfferManagerBase,
    ContextUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    function initialize() public initializer {
        __Context_init();
        __Ownable_init();
    }

    receive() external payable {}

    function register(
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        address maker,
        uint256 makerAssetId,
        uint256 makerAmount
    ) external payable returns (uint256 offerId) {
        require(_checkMaker(maker), "`maker` must not be zero.");

        // Check if given `takerTokenAddress` is either ETH or ERC20.
        if (takerTokenAddress == address(0)) {
            require(
                msg.value == takerAmount,
                "takerAmount must be the same as msg.value"
            );
        } else {
            require(
                msg.value == 0,
                "transmission method other than ETH is specified"
            );
            bool success = IERC20(takerTokenAddress).transferFrom(
                _msgSender(),
                address(this),
                takerAmount
            );
            require(success, "fail to transfer ERC20 token");
        }

        // require(
        //     makerIntmaxAddress == bytes32(0),
        //     "`makerIntmaxAddress` must be zero"
        // );

        return
            _register(
                _msgSender(), // taker
                takerIntmaxAddress,
                takerTokenAddress,
                msg.value, // takerAmount
                maker,
                bytes32(0), // anyone activates this offer
                makerAssetId,
                makerAmount
            );
    }

    function updateMaker(uint256 offerId, address newMaker) external {
        // The offer must exist.
        require(
            isRegistered(offerId),
            "This offer ID has not been registered."
        );

        // Caller must have the permission to update the offer.
        require(
            _msgSender() == _offers[offerId].taker,
            "Offers can be updated by its taker."
        );

        require(_checkMaker(newMaker), "`newMaker` should not be zero.");

        _offers[offerId].maker = newMaker;

        emit OfferMakerUpdated(offerId, newMaker);
    }

    function checkWitness(
        uint256 offerId,
        bytes calldata witness
    ) external view returns (bool) {
        _checkWitness(_offers[offerId], witness);

        return true;
    }

    function activate(
        uint256 offerId,
        bytes calldata witness
    ) external returns (bool) {
        Offer memory offer = _offers[offerId];

        // address makerIntmaxAddress = _offers[offerId].makerIntmaxAddress;
        // if (makerIntmaxAddress != address(0)) {
        //     require(
        //         witness.senderIntmax == makerIntmaxAddress,
        //         "offers can be activated by its taker"
        //     );
        // }

        _checkWitness(offer, witness);

        require(
            _msgSender() == offer.maker,
            "Only the maker can unlock this offer."
        );
        _markOfferAsActivated(offerId);

        // The maker transfers token to taker.
        payable(offer.maker).transfer(offer.takerAmount);
        if (offer.takerTokenAddress == address(0)) {
            payable(offer.maker).transfer(offer.takerAmount);
        } else {
            bool success = IERC20(offer.takerTokenAddress).transfer(
                offer.maker,
                offer.takerAmount
            );
            require(success, "fail to transfer ERC20 token");
        }

        return true;
    }

    function isRegistered(uint256 offerId) public view returns (bool) {
        return (_offers[offerId].taker != address(0));
    }

    function isActivated(uint256 offerId) public view returns (bool) {
        return _offers[offerId].isActivated;
    }

    /**
     * @dev Accepts an offer from a maker and registers it with a new offer ID.
     * @param taker is the address of the taker.
     * @param takerIntmaxAddress is the intmax address of the taker.
     * @param takerTokenAddress is the address of the token the taker will transfer.
     * @param takerAmount is the amount of token the taker will transfer.
     * @param maker is the address of the maker.
     * @param makerIntmaxAddress is the intmax address of the maker.
     * @param makerAssetId is the ID of the asset the maker will transfer on intmax.
     * @param makerAmount is the amount of asset the maker will transfer on intmax.
     * @return offerId is the ID of the newly registered offer.
     *
     * Requirements:
     * - The taker must not be the zero address.
     * - The offer ID must not be already registered.
     * - The maker's offer amount must be less than or equal to MAX_REMITTANCE_AMOUNT.
     */
    function _register(
        address taker,
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        address maker,
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount
    ) internal returns (uint256 offerId) {
        require(taker != address(0), "The taker must not be zero address.");
        offerId = _nextOfferId.current();
        require(!isRegistered(offerId), "Offer ID already registered.");

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
        _nextOfferId.increment();
        emit OfferRegistered(
            offerId,
            taker,
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            makerIntmaxAddress,
            makerAssetId,
            makerAmount
        );
        emit OfferMakerUpdated(offerId, maker);
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
     * This function activates a offer and emits an `Unlock` event.
     * @param offerId is the ID of the offer to be unlocked.
     */
    function _activate(uint256 offerId) internal {
        _markOfferAsActivated(offerId);
        emit OfferActivated(offerId, _offers[offerId].maker);
    }

    /**
     * @dev Verify the validity of the witness signature.
     * @param offer is the offer which you would like to verify.
     * @param witness is the data that needs to be verified.
     *
     * Requirements:
     * - The recovered signer from the signature must be the same as the owner address.
     */
    function _checkWitness(
        Offer memory offer,
        bytes memory witness
    ) internal view virtual {
        // bytes32 hashedMessage = ECDSA.toEthSignedMessageHash(
        //     offer.takerIntmaxAddress
        // );
        // address signer = ECDSA.recover(hashedMessage, witness);
        // require(signer == owner(), "Fail to verify signature.");
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

    function _checkMaker(address maker) internal pure returns (bool) {
        // A maker should not be the zero address.
        return maker != address(0);
    }
}
