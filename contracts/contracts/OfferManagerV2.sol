// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./OfferManager.sol";
import "./OfferManagerV2Interface.sol";
import "./utils/MerkleTree.sol";
import "./VerifierInterface.sol";

contract OfferManagerV2 is
    OfferManagerV2Interface,
    OfferManager,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    VerifierInterface verifier;
    mapping(bytes32 => bool) public usedTxHashes;
    mapping(address => bool) public tokenAllowList;

    function initialize() public override {
        OfferManager.initialize();
        initializeV2(_msgSender());
    }

    function initializeV2(address newOwner) public reinitializer(2) {
        _transferOwnership(newOwner);
    }

    function changeVerifier(VerifierInterface newVerifier) public onlyOwner {
        verifier = newVerifier;
    }

    /**
     * @custom:deprecated This function is deprecated.
     */
    function register(
        bytes32,
        uint256,
        uint256,
        address,
        bytes32,
        address,
        uint256
    )
        external
        pure
        override(OfferManager, OfferManagerInterface)
        returns (uint256)
    {
        revert("this function is deprecated: 'witness' argument required");
    }

    function register(
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        bytes memory witness
    ) public returns (uint256 offerId) {
        // Check if given `takerTokenAddress` is in the token allow list.
        require(
            tokenAllowList[takerTokenAddress],
            "the taker's token address is not in the token allow list"
        );

        offerId = _register(
            _msgSender(), // maker
            makerIntmaxAddress,
            makerAssetId,
            makerAmount,
            taker,
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount
        );

        _checkAndNullifyWitness(_offers[offerId], witness);
    }

    function activate(
        uint256 offerId
    )
        public
        payable
        override(OfferManager, OfferManagerInterface)
        returns (bool ok)
    {
        Offer storage offer = _offers[offerId];
        address taker = offer.taker;
        require(
            taker == address(0) || taker == _msgSender(),
            "offers can be activated by its taker"
        );

        // This part prevents re-entrancy attack (check and effect `offer.isActivated`).
        _activate(offerId);

        // The taker transfers his asset to maker.
        if (offer.takerTokenAddress == address(0)) {
            require(
                msg.value == offer.takerAmount,
                "please send just the amount needed to activate"
            );
            payable(offer.maker).sendValue(msg.value);
            return true;
        }

        // NOTICE: When the taker transfers ERC20 token to the maker,
        // the taker must approve the offer manager to transfer the token.
        require(msg.value == 0, "transmission method is not ETH");
        IERC20Upgradeable(offer.takerTokenAddress).safeTransferFrom(
            _msgSender(),
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

    /**
     * @custom:deprecated This function is deprecated.
     */
    function checkWitness(
        uint256 offerId,
        bytes calldata witness
    ) external view returns (bool) {
        _checkWitness(_offers[offerId], witness);

        return true;
    }

    function _checkAndNullifyWitness(
        Offer storage offer,
        bytes memory witness
    ) internal virtual {
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
     * @dev This function checks the validity of the witness signature.
     * @param offer is the offer which you would like to verify.
     * @param witness is the data that needs to be verified.
     */
    function _checkWitness(
        Offer memory offer,
        bytes memory witness
    ) internal view virtual {
        bytes32 networkIndex = verifier.networkIndex();
        (bytes32 tokenAddress, uint256 tokenId) = _decodeAssetId(
            offer.makerAssetId
        );
        VerifierInterface.Asset[] memory assets = new VerifierInterface.Asset[](
            1
        );
        assets[0] = VerifierInterface.Asset(
            tokenAddress,
            tokenId,
            offer.makerAmount
        );

        bool ok = verifier.verifyAssets(assets, networkIndex, witness);
        require(ok, "Fail to verify assets");
    }

    function _decodeAssetId(
        uint256 assetId
    ) internal pure returns (bytes32 tokenAddress, uint256 tokenId) {
        // (uint64 tokenId, uint192 rawTokenAddress) = abi.decodePacked(
        //     abi.encode(assetId),
        //     (uint64, uint192)
        // );
        tokenId = (assetId & (type(uint256).max - type(uint192).max)) >> 192;
        uint256 rawTokenAddress = assetId & type(uint192).max;
        tokenAddress = abi.decode(abi.encode(rawTokenAddress), (bytes32));
    }

    function _deactivate(uint256 offerId) internal override {
        _markOfferAsActivated(offerId);
        emit OfferActivated(offerId, _offers[offerId].makerIntmaxAddress);
    }

    /**
     * @dev Adds `token` to the allow list.
     * @param token is the address of token.
     */
    function _addTokenAddressToAllowList(address token) internal {
        _updateTokenAddressFromAllowList(token, true);
    }

    /**
     * @dev Removes `token` from the allow list.
     * @param token is the address of token.
     */
    function _removeTokenAddressFromAllowList(address token) internal {
        _updateTokenAddressFromAllowList(token, false);
    }

    function _updateTokenAddressFromAllowList(
        address token,
        bool isAllowed
    ) internal {
        if (tokenAllowList[token] != isAllowed) {
            tokenAllowList[token] = isAllowed;
            emit TokenAllowListUpdated(token, isAllowed);
        }
    }
}
