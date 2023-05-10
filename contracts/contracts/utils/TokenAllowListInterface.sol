// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface TokenAllowListInterface {
    /**
     * @dev Emitted when `token` is updated to `isAllowed`.
     * @param token is the address of token.
     */
    event TokenAllowListUpdated(address indexed token, bool isAllowed);

    function tokenAllowList(address token) external view returns (bool);

    function addTokenAddressToAllowList(address[] calldata tokens) external;

    function removeTokenAddressFromAllowList(
        address[] calldata tokens
    ) external;
}
