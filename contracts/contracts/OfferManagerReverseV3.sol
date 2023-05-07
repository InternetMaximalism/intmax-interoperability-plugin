// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerReverseV2.sol";
import "./utils/TokenAllowList.sol";

contract OfferManagerReverseV3 is OfferManagerReverseV2, TokenAllowList {
    function register(
        bytes32 takerIntmaxAddress,
        address takerTokenAddress,
        uint256 takerAmount,
        address maker,
        uint256 makerAssetId,
        uint256 makerAmount
    ) external payable override returns (uint256 offerId) {
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
            bool success = IERC20(takerTokenAddress).transferFrom(
                _msgSender(),
                address(this),
                takerAmount
            );
            require(success, "fail to transfer ERC20 token");
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
    ) external override returns (bool) {
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
        bool ok;
        if (offer.takerTokenAddress == address(0)) {
            (ok, ) = payable(offer.maker).call{value: offer.takerAmount}("");
            require(ok, "fail to transfer ETH");
            return true;
        }

        ok = IERC20(offer.takerTokenAddress).transfer(
            offer.maker,
            offer.takerAmount
        );
        require(ok, "fail to transfer ERC20 token");

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
