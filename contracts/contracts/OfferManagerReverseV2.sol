// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./OfferManagerReverse.sol";
import "./OfferManagerReverseV2Interface.sol";
import "./utils/MerkleTree.sol";
import "./VerifierInterface.sol";

contract ModifiedOfferManagerReverseV2 is
    OfferManagerReverseV2Interface,
    OfferManagerReverse
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    VerifierInterface verifier;
    mapping(bytes32 => bool) public usedTxHashes;
    mapping(address => bool) public tokenAllowList;

    /**
     * @dev Emitted when `token` is updated to `isAllowed`.
     * @param token is the address of token.
     */
    event TokenAllowListUpdated(address indexed token, bool isAllowed);

    function changeVerifier(VerifierInterface newVerifier) external onlyOwner {
        verifier = newVerifier;
    }

    function register(
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        address maker,
        uint256 makerAssetId,
        uint256 makerAmount
    )
        external
        payable
        override(OfferManagerReverse, OfferManagerReverseInterface)
        returns (uint256 offerId)
    {
        require(_checkMaker(maker), "`maker` must not be zero.");

        // Check if given `takerTokenAddress` is in the token allow list.
        require(
            tokenAllowList[takerTokenAddress],
            "the taker's token address is not in the token allow list"
        );

        if (takerTokenAddress == address(0)) {
            require(
                msg.value == takerAmount,
                "takerAmount must be the same as msg.value"
            );
        } else {
            // If it is not ETH, it is deemed to be ERC20.
            require(
                msg.value == 0,
                "transmission method other than ETH is specified"
            );
            IERC20Upgradeable(takerTokenAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                takerAmount
            );
        }

        return
            _register(
                _msgSender(), // taker
                takerIntmaxAddress,
                takerTokenAddress,
                takerAmount, // takerAmount
                maker,
                bytes32(0), // anyone activates this offer
                makerAssetId,
                makerAmount
            );
    }

    function activate(
        uint256 offerId,
        bytes calldata witness
    )
        external
        override(OfferManagerReverse, OfferManagerReverseInterface)
        returns (bool ok)
    {
        Offer memory offer = _offers[offerId];

        // address makerIntmaxAddress = _offers[offerId].makerIntmaxAddress;
        // if (makerIntmaxAddress != address(0)) {
        //     require(
        //         witness.senderIntmax == makerIntmaxAddress,
        //         "offers can be activated by its taker"
        //     );
        // }

        require(
            offer.maker == _msgSender(),
            "Only the maker can unlock this offer."
        );

        _checkAndNullifyWitness(_offers[offerId], witness);

        _activate(offerId);

        // The maker transfers token to taker.
        if (offer.takerTokenAddress == address(0)) {
            payable(offer.maker).sendValue(offer.takerAmount);
            return true;
        }

        IERC20Upgradeable(offer.takerTokenAddress).safeTransfer(
            offer.maker,
            offer.takerAmount
        );

        return true;
    }

    function addTokenAddressToAllowList(
        address[] calldata tokens
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            _addTokenAddressToAllowList(tokens[i]);
        }
    }

    function removeTokenAddressFromAllowList(
        address[] calldata tokens
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            _removeTokenAddressFromAllowList(tokens[i]);
        }
    }

    function _checkAndNullifyWitness(
        Offer storage offer,
        bytes memory witness
    ) internal {
        (, , MerkleTree.MerkleProof memory diffTreeInclusionProof, , ) = abi
            .decode(
                witness,
                (
                    VerifierInterface.Asset[],
                    bytes32,
                    MerkleTreeInterface.MerkleProof,
                    VerifierInterface.BlockHeader,
                    bytes
                )
            );
        bytes32 txHash = diffTreeInclusionProof.value;
        require(!usedTxHashes[txHash], "Given witness already used");
        _checkWitness(offer, witness);
        usedTxHashes[txHash] = true;
    }

    /**
     * @dev Adds `token` to the allow list.
     * @param token is the address of token.
     */
    function _addTokenAddressToAllowList(address token) internal {
        tokenAllowList[token] = true;
        emit TokenAllowListUpdated(token, true);
    }

    /**
     * @dev Removes `token` from the allow list.
     * @param token is the address of token.
     */
    function _removeTokenAddressFromAllowList(address token) internal {
        tokenAllowList[token] = false;
        emit TokenAllowListUpdated(token, false);
    }

    /**
     * @dev This function checks the validity of the witness signature.
     * @param offer is the offer which you would like to verify.
     * @param witness is the data that needs to be verified.
     */
    function _checkWitness(
        Offer memory offer,
        bytes memory witness
    ) internal view override {
        bytes32 tokenAddress = abi.decode(
            abi.encode(offer.makerAssetId),
            (bytes32)
        );
        uint256 tokenId = 0; // TODO
        VerifierInterface.Asset[] memory assets = new VerifierInterface.Asset[](
            1
        );
        assets[0] = VerifierInterface.Asset(
            tokenAddress,
            tokenId,
            offer.makerAmount
        );
        bool ok = verifier.verifyAssets(
            assets,
            offer.takerIntmaxAddress,
            witness
        );
        require(ok, "Fail to verify assets");
    }
}
