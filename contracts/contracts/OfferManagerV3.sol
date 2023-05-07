// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./OfferManagerV2.sol";
import "hardhat/console.sol";

contract OfferManagerV3 is OfferManagerV2 {
    mapping(address => bool) public tokenAllowList;

    /**
     * @dev Emitted when `token` is updated to `isAllowed`.
     * @param token is the address of token.
     */
    event TokenAllowListUpdated(address indexed token, bool isAllowed);

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
        // Check if given `takerTokenAddress` is either ETH (= zero address) or ERC20.
        require(
            takerTokenAddress == address(0) ||
                tokenAllowList[takerTokenAddress],
            "the taker's token address is neither ETH nor ERC20"
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
        _checkWitness(_offers[offerId], witness);
        usedTxHashes[txHash] = true;

        return offerId;
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
}
