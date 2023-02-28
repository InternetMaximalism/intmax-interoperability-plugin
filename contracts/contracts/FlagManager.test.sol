// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./FlagManager.sol";

contract FlagManagerTest is FlagManager {
    /**
     * This test function can activate the flag without actually making the transfer.
     * @param flagId is the ID of the flag.
     */
    function testActivate(uint256 flagId) public returns (bool) {
        _activate(flagId);

        return true;
    }
}
