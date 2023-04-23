// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OfferManager.sol";
import "./OfferManagerV2Interface.sol";
import "./VerifierInterface.sol";

contract OfferManagerV2 is
    OfferManager,
    OfferManagerV2Interface,
    OwnableUpgradeable
{
    VerifierInterface verifier;

    function initialize() public override initializer {
        __Context_init();
        __Ownable_init();
    }

    function changeVerifier(VerifierInterface newVerifier) external onlyOwner {
        verifier = newVerifier;
    }

    /**
     * @notice This function is deprecated.
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
        revert("this function is deprecated");
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
    ) external returns (uint256 offerId) {
        // Check if given `takerTokenAddress` is either ETH or ERC20.
        if (takerTokenAddress != address(0)) {
            uint256 totalSupply = IERC20(takerTokenAddress).totalSupply();
            require(
                totalSupply != 0,
                "the total supply of ERC20 must not be zero"
            );
        }

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

        _checkWitness(_offers[offerId], witness);

        return offerId;
    }

    function checkWitness(
        uint256 offerId,
        bytes calldata witness
    ) external view returns (bool) {
        _checkWitness(_offers[offerId], witness);

        return true;
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
        bytes32 networkIndex = verifier.networkIndex();
        bytes32 tokenAddress = abi.decode(
            abi.encode(offer.makerAssetId),
            (bytes32)
        );
        uint256 tokenId = 0; // TODO
        VerifierInterface.Asset memory asset = VerifierInterface.Asset(
            networkIndex,
            tokenAddress,
            tokenId,
            offer.makerAmount
        );
        verifier.verifyAsset(asset, witness);
    }
}
