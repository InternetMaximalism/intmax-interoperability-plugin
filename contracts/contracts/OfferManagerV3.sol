// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./OfferManagerV2.sol";
import "./utils/TokenAllowList.sol";

contract OfferManagerV3 is OfferManagerV2, TokenAllowList {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function register(
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount,
        address taker,
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        bytes memory witness
    ) external override returns (uint256 offerId) {
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
    ) external payable override returns (bool ok) {
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
            (ok, ) = payable(offer.maker).call{value: msg.value}("");
            require(ok, "fail to transfer ETH");
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
}
