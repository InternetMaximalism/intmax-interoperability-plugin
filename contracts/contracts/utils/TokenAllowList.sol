// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

abstract contract TokenAllowList {
    mapping(address => bool) public tokenAllowList;

    /**
     * @dev Emitted when `token` is updated to `isAllowed`.
     * @param token is the address of token.
     */
    event TokenAllowListUpdated(address indexed token, bool isAllowed);

    /**
     * @dev Adds `token` to the allow list.
     * @param token is the address of token.
     */
    function _addTokenAddressToAllowList(address token) internal {
        tokenAllowList[token] = true;
        emit TokenAllowListUpdated(token, true);
    }

    /**
     * @dev Removes `token` from the allow list.
     * @param token is the address of token.
     */
    function _removeTokenAddressFromAllowList(address token) internal {
        tokenAllowList[token] = false;
        emit TokenAllowListUpdated(token, false);
    }

    uint256[49] private __gap;
}
