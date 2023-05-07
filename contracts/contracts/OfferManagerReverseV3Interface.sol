// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./OfferManagerReverseInterface.sol";

interface OfferManagerReverseV3Interface is OfferManagerReverseInterface {
    function addTokenAddressToAllowList(address[] calldata tokens) external;

    function removeTokenAddressFromAllowList(
        address[] calldata tokens
    ) external;
}
