// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OfferManager.sol";
import "./Verifier.sol";

// import "./utils/MerkleTree.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// NOTICE: This contract is not upgradeable.
contract OfferManagerV2 is OfferManager, OwnableUpgradeable, Verifier {
    function initialize() public override initializer {
        __Context_init();
        __Ownable_init();
    }

    /**
     * Emits an `OfferActivated` event with the offer ID and the taker's Intmax address.
     */
    function activate(
        uint256 offerId
    ) external payable override returns (bool) {
        bytes memory witness = "";
        return activate(offerId, witness);
    }

    /**
     * Emits an `OfferActivated` event with the offer ID and the taker's Intmax address.
     */
    function activate(
        uint256 offerId,
        bytes memory witness
    ) public payable returns (bool) {
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

        _checkWitness(offer, witness);

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
        // (
        //     bytes32 r,
        //     bytes32 s,
        //     uint8 v,
        //     bytes32 root,
        //     uint256 index,
        //     bytes32 value,
        //     bytes32[] memory siblings
        // ) = abi.decode(
        //         witness,
        //         (bytes32, bytes32, uint8, bytes32, uint256, bytes32, bytes32[])
        //     );
        // bytes memory signature = abi.encodePacked(r, s, v);
        // MerkleTree.MerkleProof memory merkleProof = MerkleTree.MerkleProof {
        //     index: index,
        //     leaf: value,
        //     siblings: siblings,
        // };
        // MerkleTree.verify(siblings, root, index, value);
        // bytes32 hashedMessage = ECDSA.toEthSignedMessageHash(root);
        // address signer = ECDSA.recover(hashedMessage, signature);
        // require(signer == owner(), "Fail to verify signature.");
        // verifyTransaction(
        //     merkleProof,
        //     blockHeader,
        //     blockHash,
        //     signature,
        //     owner()
        // );
    }
}
