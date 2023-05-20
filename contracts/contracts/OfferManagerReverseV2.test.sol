// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./SimpleVerifier.test.sol";
import "./OfferManagerReverseV2.sol";

contract OfferManagerReverseV2Test is OfferManagerReverseV2 {
    constructor() {
        initialize();
    }
}

contract OfferManagerReverseV2Wrapper is OfferManagerReverseV2 {
    constructor() {
        initialize();
    }

    function _checkAndNullifyWitness(
        Offer storage,
        bytes memory
    ) internal override {}
}

contract OfferManagerReverseV2ForgeTest is Test {
    address maker;
    address taker;

    SimpleVerifier verifier;
    OfferManagerReverseV2Wrapper offerManager;

    bytes32 constant NETWORK_INDEX = bytes32("2");
    uint256 constant MAX_REMITTANCE_AMOUNT = 18446744069414584320; // the maximum value of Goldilocks field

    function setUp() external {
        string
            memory mnemonic = "test test test test test test test test test test test junk";
        {
            uint256 privateKey = vm.deriveKey(mnemonic, 0);
            maker = vm.addr(privateKey);
            vm.deal(maker, 100 ether);
        }
        {
            uint256 privateKey = vm.deriveKey(mnemonic, 1);
            taker = vm.addr(privateKey);
            vm.deal(taker, 100 ether);
        }

        verifier = new SimpleVerifierTest(NETWORK_INDEX);
        offerManager = new OfferManagerReverseV2Wrapper();
        offerManager.changeVerifier(VerifierInterface(verifier));
        address[] memory newAllowList = new address[](1);
        newAllowList[0] = address(0);
        offerManager.addTokenAddressToAllowList(newAllowList);
    }

    function testRegister(
        uint256 makerAssetId,
        uint256 makerAmount,
        bytes32 takerIntmaxAddress,
        uint256 takerAmount,
        address[] memory newMakers
    ) external {
        address takerTokenAddress = address(0);
        bytes memory witness = "0x";
        vm.assume(makerAmount <= MAX_REMITTANCE_AMOUNT);
        vm.assume(takerAmount <= 100 ether);
        vm.assume(newMakers.length < 3);
        vm.prank(taker);
        uint256 offerId = offerManager.register{value: takerAmount}(
            takerIntmaxAddress,
            takerTokenAddress,
            takerAmount,
            maker,
            makerAssetId,
            makerAmount
        );

        address newMaker = maker;
        for (uint256 i = 0; i < newMakers.length; i++) {
            vm.assume(newMakers[i] != address(0));
            vm.prank(taker);
            offerManager.updateMaker(offerId, newMakers[i]);
            newMaker = newMakers[i];
        }

        vm.prank(newMaker);
        bool ok = offerManager.activate(offerId, witness);
        assertEq(ok, true);
    }
}
