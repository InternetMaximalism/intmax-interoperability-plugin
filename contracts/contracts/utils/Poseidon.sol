// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library GoldilocksPoseidon {
    // uint256 constant HALF_N_FULL_ROUNDS = 0;
    // uint256 constant N_PARTIAL_ROUNDS = 0;
    // uint256 constant N_ROUNDS = 2 * HALF_N_FULL_ROUNDS + N_PARTIAL_ROUNDS;

    // bytes constant FAST_PARTIAL_ROUND_CONSTANTS = "";

    function two_to_one(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        // TODO
        // uint64[12] memory state = abi.decode(
        //     abi.encodePacked(a, b),
        //     (uint64[12])
        // );
        // state = _poseidon(state);
        // return
        //     abi.decode(
        //         abi.encodePacked(state[0], state[1], state[2], state[3]),
        //         (bytes32)
        //     );
        return sha256(abi.encodePacked(a, b));
    }

    // function _poseidon(
    //     uint64[12] memory state
    // ) internal pure returns (uint64[12] memory) {
    //     uint256 roundCounter = 0;

    //     (state, roundCounter) = _fullRounds(state, roundCounter);
    //     (state, roundCounter) = _partialRounds(state, roundCounter);
    //     (state, roundCounter) = _fullRounds(state, roundCounter);
    //     require(roundCounter == N_ROUNDS, "incorrect round counter");

    //     return state;
    // }

    // function _fullRounds(
    //     uint64[12] memory state,
    //     uint256 roundCounter
    // ) internal pure returns (uint64[12] memory, uint256) {
    //     for (uint256 i = 0; i < HALF_N_FULL_ROUNDS; i++) {
    //         (state, roundCounter) = _constantLayer(state, roundCounter);
    //         roundCounter += 1;
    //         state = _sboxLayer(state);
    //         state = _mdsLayer(state);
    //     }

    //     return (state, roundCounter);
    // }

    // function _partialRounds(
    //     uint64[12] memory state,
    //     uint256 roundCounter
    // ) internal pure returns (uint64[12] memory, uint256) {
    //     state = _partialFirstConstantLayer(state);
    //     state = _mdsPartialLayerInit(state);

    //     for (uint256 i = 0; i < N_PARTIAL_ROUNDS; i++) {
    //         state[0] = _sboxMonomial(state[0]);
    //         state[0] = _addCanonicalU64(state[0], _getPartialRoundConstants(i));
    //         state = _mdsPartialLayerFast(state, i);
    //     }
    //     roundCounter += N_PARTIAL_ROUNDS;

    //     return (state, roundCounter);
    // }

    // function _sboxLayer(
    //     uint64[12] memory state
    // ) internal pure returns (uint64[12] memory) {}

    // function _sboxMonomial(uint64 state0) internal pure returns (uint64) {}

    // function _constantLayer(
    //     uint64[12] memory state,
    //     uint256 roundCounter
    // ) internal pure returns (uint64[12] memory, uint256) {}

    // function _partialFirstConstantLayer(
    //     uint64[12] memory state
    // ) internal pure returns (uint64[12] memory) {}

    // function _addCanonicalU64(
    //     uint64 state0,
    //     uint64 roundConstant
    // ) internal pure returns (uint64) {}

    // function _mdsLayer(
    //     uint64[12] memory state
    // ) internal pure returns (uint64[12] memory) {}

    // function _mdsPartialLayerInit(
    //     uint64[12] memory state
    // ) internal pure returns (uint64[12] memory) {}

    // function _mdsPartialLayerFast(
    //     uint64[12] memory state,
    //     uint256 roundCounter
    // ) internal pure returns (uint64[12] memory) {}

    // function _getPartialRoundConstants(
    //     uint256 roundCounter
    // ) internal pure returns (uint64 roundConstant) {
    //     roundConstant = abi.decode(
    //         abi.encodePacked(
    //             FAST_PARTIAL_ROUND_CONSTANTS[8 * roundCounter],
    //             FAST_PARTIAL_ROUND_CONSTANTS[8 * roundCounter + 1],
    //             FAST_PARTIAL_ROUND_CONSTANTS[8 * roundCounter + 2],
    //             FAST_PARTIAL_ROUND_CONSTANTS[8 * roundCounter + 3],
    //             FAST_PARTIAL_ROUND_CONSTANTS[8 * roundCounter + 4],
    //             FAST_PARTIAL_ROUND_CONSTANTS[8 * roundCounter + 5],
    //             FAST_PARTIAL_ROUND_CONSTANTS[8 * roundCounter + 6],
    //             FAST_PARTIAL_ROUND_CONSTANTS[8 * roundCounter + 7]
    //         ),
    //         (uint64)
    //     );
    // }
}
