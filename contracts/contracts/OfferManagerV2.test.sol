// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./SimpleVerifier.test.sol";
import "./OfferManagerV2.sol";

contract OfferManagerV2Test is OfferManagerV2 {
    constructor() {
        initialize();
    }
}

contract OfferManagerV2Wrapper is OfferManagerV2 {
    constructor() {
        initialize();
    }

    function checkTaker(bytes32 taker) external pure returns (bool ok) {
        return _checkTaker(taker);
    }

    function _checkAndNullifyWitness(
        Offer storage,
        bytes memory
    ) internal override {}
}

contract OfferManagerV2ForgeTest is Test {
    address maker;
    address taker;

    SimpleVerifier verifier;
    OfferManagerV2Wrapper offerManager;

    bytes32 constant NETWORK_INDEX = bytes32("2");
    uint256 constant MAX_REMITTANCE_AMOUNT = 18446744069414584320; // the maximum value of Goldilocks field

    function setUp() external {
        string
            memory mnemonic = "test test test test test test test test test test test junk";
        {
            uint256 privateKey = vm.deriveKey(mnemonic, 0);
            maker = vm.addr(privateKey);
        }
        {
            uint256 privateKey = vm.deriveKey(mnemonic, 1);
            taker = vm.addr(privateKey);
            vm.deal(taker, 100 ether);
        }

        verifier = new SimpleVerifierTest(NETWORK_INDEX);
        offerManager = new OfferManagerV2Wrapper();
        offerManager.changeVerifier(VerifierInterface(verifier));
        address[] memory newAllowList = new address[](1);
        newAllowList[0] = address(0);
        offerManager.addTokenAddressToAllowList(newAllowList);
    }

    function testRegisterActivate(
        bytes32 makerIntmaxAddress,
        uint256 makerAssetId,
        uint256 makerAmount,
        bytes32 takerIntmaxAddress,
        uint256 takerAmount,
        bytes32[] memory newTakers
    ) external {
        address takerTokenAddress = address(0);
        bytes memory witness = "0x";
        vm.assume(makerAmount <= MAX_REMITTANCE_AMOUNT);
        vm.assume(takerAmount <= 100 ether);
        vm.assume(newTakers.length < 3);
        vm.prank(maker);
        uint256 offerId = offerManager.register(
            makerIntmaxAddress,
            makerAssetId,
            makerAmount,
            taker,
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            witness
        );

        for (uint256 i = 0; i < newTakers.length; i++) {
            vm.assume(offerManager.checkTaker(newTakers[i]));
            vm.prank(maker);
            offerManager.updateTaker(offerId, newTakers[i]);
        }

        vm.prank(taker);
        bool ok = offerManager.activate{value: takerAmount}(offerId);
        assertEq(ok, true);
    }
}
