// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./FlagManager.sol";

contract FlagManagerTest is FlagManager {
    /**
     * This function registers a new flag.
     * @param recipient is the account you want to transfer.
     * @param assetId is the asset ID you want to transfer.
     * @param amount is the amount you want to transfer.
     */
    function testRegister(
        bytes32 recipient,
        uint256 assetId,
        uint256 amount
    ) external returns (uint256 flagId) {
        return _register(recipient, assetId, amount);
    }

    /**
     * This test function can activate the flag without actually making the transfer.
     * @param flagId is the ID of the flag.
     */
    function testActivate(uint256 flagId) external returns (bool) {
        _activate(flagId);

        return true;
    }
}
