// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./Poseidon.sol";

contract PoseidonTest is GoldilocksPoseidon {
    function testPoseidon() public view {
        uint256[] memory input = new uint256[](1);
        input[0] = 1;
        uint256 gasBefore = gasleft();
        uint256[] memory output = _hashNToMNoPad(input, 4);
        uint256 gasAfter = gasleft();
        console.log("used gas: %d", gasBefore - gasAfter);
        assert(output[0] == 15020833855946683413);
        assert(output[1] == 2541896837400596712);
        assert(output[2] == 5158482081674306993);
        assert(output[3] == 15736419290823331982);
    }
}

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
