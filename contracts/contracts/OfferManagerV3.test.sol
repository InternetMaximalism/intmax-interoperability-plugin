// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerV3.sol";
import "./OfferManagerV2.test.sol";

contract OfferManagerV3Test is OfferManagerV3 {
    constructor() {
        initialize();
    }
}
