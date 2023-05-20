// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./Poseidon.sol";

contract PoseidonForgeTest is Test {
    GoldilocksPoseidon poseidon;

    function setUp() external {
        poseidon = new GoldilocksPoseidon();
    }

    function testTwoToOne(
        bytes32 left,
        bytes32 right
    ) external view returns (bytes32 output) {
        output = poseidon.twoToOne(left, right);
    }

    function testHashNToMNoPad(
        uint256[] memory input,
        uint256 numOutputs
    ) external returns (uint256[] memory output) {
        // vm.assume(input.length != 0);
        vm.assume(input.length < 50);
        // vm.assume(numOutputs != 0);
        vm.assume(numOutputs < 8);
        output = poseidon.hashNToMNoPad(input, numOutputs);
        assertEq(output.length, numOutputs);
    }
}
