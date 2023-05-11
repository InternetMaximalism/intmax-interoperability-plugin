// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerReverseInterface.sol";
import "./utils/TokenAllowListInterface.sol";

interface OfferManagerReverseV2Interface is
    OfferManagerReverseInterface,
    TokenAllowListInterface
{}
