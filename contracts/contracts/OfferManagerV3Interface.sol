// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerV2Interface.sol";

interface OfferManagerV3Interface is OfferManagerV2Interface {
    function addTokenAddressToAllowList(address[] calldata tokens) external;

    function removeTokenAddressFromAllowList(
        address[] calldata tokens
    ) external;
}
