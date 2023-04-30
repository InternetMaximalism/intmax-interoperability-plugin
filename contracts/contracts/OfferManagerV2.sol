// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OfferManager.sol";
import "./OfferManagerV2Interface.sol";
import "./utils/MerkleTree.sol";
import "./VerifierInterface.sol";

contract OfferManagerV2 is
    OfferManagerV2Interface,
    OfferManager,
    OwnableUpgradeable
{
    VerifierInterface verifier;
    mapping(bytes32 => bool) public usedTxHashes;

    function initialize() public override {
        OfferManager.initialize();
        initializeV2(_msgSender());
    }

    function initializeV2(address newOwner) public reinitializer(2) {
        // NOTICE: Using `__Ownable_init()` sets the proxyAdmin as owner.
        _transferOwnership(newOwner);
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

    function checkWitness(
        uint256 offerId,
        bytes calldata witness
    ) external view returns (bool) {
        _checkWitness(_offers[offerId], witness);

        return true;
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

        bool ok = verifier.verifyAssets(assets, networkIndex, witness);
        require(ok, "Fail to verify assets");
    }

    function _deactivate(uint256 offerId) internal {
        _markOfferAsActivated(offerId);
        emit OfferActivated(offerId, _offers[offerId].makerIntmaxAddress);
    }
}
