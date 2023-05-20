// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract GoldilocksPoseidon {
    uint256 constant HALF_N_FULL_ROUNDS = 4;
    uint256 constant N_FULL_ROUNDS_TOTAL = 2 * HALF_N_FULL_ROUNDS;
    uint256 constant N_PARTIAL_ROUNDS = 22;
    uint256 constant N_ROUNDS = N_FULL_ROUNDS_TOTAL + N_PARTIAL_ROUNDS;
    uint256 constant MAX_WIDTH = 12;
    uint256 constant WIDTH = 12;
    uint256 constant SPONGE_RATE = 8;
    uint256 constant ORDER = 18446744069414584321;
    uint256 constant MDS_MATRIX_CIRC_0 = 17;
    uint256 constant MDS_MATRIX_CIRC_1 = 15;
    uint256 constant MDS_MATRIX_CIRC_2 = 41;
    uint256 constant MDS_MATRIX_CIRC_3 = 16;
    uint256 constant MDS_MATRIX_CIRC_4 = 2;
    uint256 constant MDS_MATRIX_CIRC_5 = 28;
    uint256 constant MDS_MATRIX_CIRC_6 = 13;
    uint256 constant MDS_MATRIX_CIRC_7 = 13;
    uint256 constant MDS_MATRIX_CIRC_8 = 39;
    uint256 constant MDS_MATRIX_CIRC_9 = 18;
    uint256 constant MDS_MATRIX_CIRC_10 = 34;
    uint256 constant MDS_MATRIX_CIRC_11 = 20;

    uint256 constant MDS_MATRIX_DIAG_0 = 8;

    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_0 = 0x3cc3f892184df408;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_1 = 0xe993fd841e7e97f1;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_2 = 0xf2831d3575f0f3af;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_3 = 0xd2500e0a350994ca;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_4 = 0xc5571f35d7288633;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_5 = 0x91d89c5184109a02;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_6 = 0xf37f925d04e5667b;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_7 = 0x2d6e448371955a69;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_8 = 0x740ef19ce01398a1;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_9 = 0x694d24c0752fdf45;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_10 = 0x60936af96ee2f148;
    uint256 constant FAST_PARTIAL_FIRST_ROUND_CONSTANT_11 = 0xc33448feadc78f0c;

    function mod(uint256 a) internal pure returns (uint256 res) {
        assembly {
            res := mod(a, ORDER)
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            res := addmod(a, b, ORDER)
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf0(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            // res = add(res, state[r] * MDS_MATRIX_DIAG[r]); // 200 bits
            res =
                state[1] *
                MDS_MATRIX_CIRC_1 +
                state[2] *
                MDS_MATRIX_CIRC_2 +
                (state[3] << 4) + // state[3] * MDS_MATRIX_CIRC_3
                state[4] *
                MDS_MATRIX_CIRC_4 +
                state[5] *
                MDS_MATRIX_CIRC_5 +
                state[6] *
                MDS_MATRIX_CIRC_6 +
                state[7] *
                MDS_MATRIX_CIRC_7 +
                state[8] *
                MDS_MATRIX_CIRC_8 +
                state[9] *
                MDS_MATRIX_CIRC_9 +
                state[10] *
                MDS_MATRIX_CIRC_10 +
                state[11] *
                MDS_MATRIX_CIRC_11 +
                state[0] *
                (MDS_MATRIX_CIRC_0 + MDS_MATRIX_DIAG_0);
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf1(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[1] *
                MDS_MATRIX_CIRC_0 +
                state[2] *
                MDS_MATRIX_CIRC_1 +
                state[3] *
                MDS_MATRIX_CIRC_2 +
                (state[4] << 4) + // state[4] * MDS_MATRIX_CIRC_3
                state[5] *
                MDS_MATRIX_CIRC_4 +
                state[6] *
                MDS_MATRIX_CIRC_5 +
                state[7] *
                MDS_MATRIX_CIRC_6 +
                state[8] *
                MDS_MATRIX_CIRC_7 +
                state[9] *
                MDS_MATRIX_CIRC_8 +
                state[10] *
                MDS_MATRIX_CIRC_9 +
                state[11] *
                MDS_MATRIX_CIRC_10 +
                state[0] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf2(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[2] *
                MDS_MATRIX_CIRC_0 +
                state[3] *
                MDS_MATRIX_CIRC_1 +
                state[4] *
                MDS_MATRIX_CIRC_2 +
                (state[5] << 4) + // state[5] * MDS_MATRIX_CIRC_3
                state[6] *
                MDS_MATRIX_CIRC_4 +
                state[7] *
                MDS_MATRIX_CIRC_5 +
                state[8] *
                MDS_MATRIX_CIRC_6 +
                state[9] *
                MDS_MATRIX_CIRC_7 +
                state[10] *
                MDS_MATRIX_CIRC_8 +
                state[11] *
                MDS_MATRIX_CIRC_9 +
                state[0] *
                MDS_MATRIX_CIRC_10 +
                state[1] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf3(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[3] *
                MDS_MATRIX_CIRC_0 +
                state[4] *
                MDS_MATRIX_CIRC_1 +
                state[5] *
                MDS_MATRIX_CIRC_2 +
                (state[6] << 4) + // state[6] * MDS_MATRIX_CIRC_3
                state[7] *
                MDS_MATRIX_CIRC_4 +
                state[8] *
                MDS_MATRIX_CIRC_5 +
                state[9] *
                MDS_MATRIX_CIRC_6 +
                state[10] *
                MDS_MATRIX_CIRC_7 +
                state[11] *
                MDS_MATRIX_CIRC_8 +
                state[0] *
                MDS_MATRIX_CIRC_9 +
                state[1] *
                MDS_MATRIX_CIRC_10 +
                state[2] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf4(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[4] *
                MDS_MATRIX_CIRC_0 +
                state[5] *
                MDS_MATRIX_CIRC_1 +
                state[6] *
                MDS_MATRIX_CIRC_2 +
                (state[7] << 4) + // state[7] * MDS_MATRIX_CIRC_3
                state[8] *
                MDS_MATRIX_CIRC_4 +
                state[9] *
                MDS_MATRIX_CIRC_5 +
                state[10] *
                MDS_MATRIX_CIRC_6 +
                state[11] *
                MDS_MATRIX_CIRC_7 +
                state[0] *
                MDS_MATRIX_CIRC_8 +
                state[1] *
                MDS_MATRIX_CIRC_9 +
                state[2] *
                MDS_MATRIX_CIRC_10 +
                state[3] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf5(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[5] *
                MDS_MATRIX_CIRC_0 +
                state[6] *
                MDS_MATRIX_CIRC_1 +
                state[7] *
                MDS_MATRIX_CIRC_2 +
                (state[8] << 4) + // state[8] * MDS_MATRIX_CIRC_3
                state[9] *
                MDS_MATRIX_CIRC_4 +
                state[10] *
                MDS_MATRIX_CIRC_5 +
                state[11] *
                MDS_MATRIX_CIRC_6 +
                state[0] *
                MDS_MATRIX_CIRC_7 +
                state[1] *
                MDS_MATRIX_CIRC_8 +
                state[2] *
                MDS_MATRIX_CIRC_9 +
                state[3] *
                MDS_MATRIX_CIRC_10 +
                state[4] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf6(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[6] *
                MDS_MATRIX_CIRC_0 +
                state[7] *
                MDS_MATRIX_CIRC_1 +
                state[8] *
                MDS_MATRIX_CIRC_2 +
                (state[9] << 4) + // state[9] * MDS_MATRIX_CIRC_3
                state[10] *
                MDS_MATRIX_CIRC_4 +
                state[11] *
                MDS_MATRIX_CIRC_5 +
                state[0] *
                MDS_MATRIX_CIRC_6 +
                state[1] *
                MDS_MATRIX_CIRC_7 +
                state[2] *
                MDS_MATRIX_CIRC_8 +
                state[3] *
                MDS_MATRIX_CIRC_9 +
                state[4] *
                MDS_MATRIX_CIRC_10 +
                state[5] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf7(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[7] *
                MDS_MATRIX_CIRC_0 +
                state[8] *
                MDS_MATRIX_CIRC_1 +
                state[9] *
                MDS_MATRIX_CIRC_2 +
                (state[10] << 4) + // state[10] * MDS_MATRIX_CIRC_3
                state[11] *
                MDS_MATRIX_CIRC_4 +
                state[0] *
                MDS_MATRIX_CIRC_5 +
                state[1] *
                MDS_MATRIX_CIRC_6 +
                state[2] *
                MDS_MATRIX_CIRC_7 +
                state[3] *
                MDS_MATRIX_CIRC_8 +
                state[4] *
                MDS_MATRIX_CIRC_9 +
                state[5] *
                MDS_MATRIX_CIRC_10 +
                state[6] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf8(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[8] *
                MDS_MATRIX_CIRC_0 +
                state[9] *
                MDS_MATRIX_CIRC_1 +
                state[10] *
                MDS_MATRIX_CIRC_2 +
                (state[11] << 4) + // state[11] * MDS_MATRIX_CIRC_3
                state[0] *
                MDS_MATRIX_CIRC_4 +
                state[1] *
                MDS_MATRIX_CIRC_5 +
                state[2] *
                MDS_MATRIX_CIRC_6 +
                state[3] *
                MDS_MATRIX_CIRC_7 +
                state[4] *
                MDS_MATRIX_CIRC_8 +
                state[5] *
                MDS_MATRIX_CIRC_9 +
                state[6] *
                MDS_MATRIX_CIRC_10 +
                state[7] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf9(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[9] *
                MDS_MATRIX_CIRC_0 +
                state[10] *
                MDS_MATRIX_CIRC_1 +
                state[11] *
                MDS_MATRIX_CIRC_2 +
                (state[0] << 4) + // state[0] * MDS_MATRIX_CIRC_3
                state[1] *
                MDS_MATRIX_CIRC_4 +
                state[2] *
                MDS_MATRIX_CIRC_5 +
                state[3] *
                MDS_MATRIX_CIRC_6 +
                state[4] *
                MDS_MATRIX_CIRC_7 +
                state[5] *
                MDS_MATRIX_CIRC_8 +
                state[6] *
                MDS_MATRIX_CIRC_9 +
                state[7] *
                MDS_MATRIX_CIRC_10 +
                state[8] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf10(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[10] *
                MDS_MATRIX_CIRC_0 +
                state[11] *
                MDS_MATRIX_CIRC_1 +
                state[0] *
                MDS_MATRIX_CIRC_2 +
                (state[1] << 4) + // state[1] * MDS_MATRIX_CIRC_3
                state[2] *
                MDS_MATRIX_CIRC_4 +
                state[3] *
                MDS_MATRIX_CIRC_5 +
                state[4] *
                MDS_MATRIX_CIRC_6 +
                state[5] *
                MDS_MATRIX_CIRC_7 +
                state[6] *
                MDS_MATRIX_CIRC_8 +
                state[7] *
                MDS_MATRIX_CIRC_9 +
                state[8] *
                MDS_MATRIX_CIRC_10 +
                state[9] *
                MDS_MATRIX_CIRC_11;
        }
    }

    // `state[r]` allows 192 bits number.
    // `res` is 200 bits number.
    function _mdsRowShf11(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256 res) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     res += state[(i + r) % WIDTH] * MDS_MATRIX_CIRC[i]; // (192 + 8) bits
            // }
            res =
                state[11] *
                MDS_MATRIX_CIRC_0 +
                state[0] *
                MDS_MATRIX_CIRC_1 +
                state[1] *
                MDS_MATRIX_CIRC_2 +
                (state[2] << 4) + // state[2] * MDS_MATRIX_CIRC_3
                state[3] *
                MDS_MATRIX_CIRC_4 +
                state[4] *
                MDS_MATRIX_CIRC_5 +
                state[5] *
                MDS_MATRIX_CIRC_6 +
                state[6] *
                MDS_MATRIX_CIRC_7 +
                state[7] *
                MDS_MATRIX_CIRC_8 +
                state[8] *
                MDS_MATRIX_CIRC_9 +
                state[9] *
                MDS_MATRIX_CIRC_10 +
                state[10] *
                MDS_MATRIX_CIRC_11;
        }
    }

    function _mdsPartialLayerInit1(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0x80772dc2645b280b +
                state[2] *
                0xe796d293a47a64cb +
                state[3] *
                0xdcedab70f40718ba +
                state[4] *
                0xf4a437f2888ae909 +
                state[5] *
                0xf97abba0dffb6c50 +
                state[6] *
                0x7f8e41e0b0a6cdff +
                state[7] *
                0x726af914971c1374 +
                state[8] *
                0x64dd936da878404d +
                state[9] *
                0x85418a9fef8a9890 +
                state[10] *
                0x156048ee7a738154 +
                state[11] *
                0xd841e8ef9dde8ba0;
        }
    }

    function _mdsPartialLayerInit2(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0xdc927721da922cf8 +
                state[2] *
                0xb124c33152a2421a +
                state[3] *
                0x14a4a64da0b2668f +
                state[4] *
                0xc537d44dc2875403 +
                state[5] *
                0x5e40f0c9bb82aab5 +
                state[6] *
                0x4b1ba8d40afca97d +
                state[7] *
                0x1d7f8a2cce1a9d00 +
                state[8] *
                0x4db9a2ead2bd7262 +
                state[9] *
                0xd8a2eb7ef5e707ad +
                state[10] *
                0x91f7562377e81df5 +
                state[11] *
                0x156048ee7a738154;
        }
    }

    function _mdsPartialLayerInit3(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0xc1978156516879ad +
                state[2] *
                0x0ee5dc0ce131268a +
                state[3] *
                0x4715b8e5ab34653b +
                state[4] *
                0x7f68007619fd8ba9 +
                state[5] *
                0x5996a80497e24a6b +
                state[6] *
                0x623708f28fca70e8 +
                state[7] *
                0x18737784700c75cd +
                state[8] *
                0xbe2e19f6d07f1a83 +
                state[9] *
                0xbfe85ababed2d882 +
                state[10] *
                0xd8a2eb7ef5e707ad +
                state[11] *
                0x85418a9fef8a9890;
        }
    }

    function _mdsPartialLayerInit4(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0x90e80c591f48b603 +
                state[2] *
                0xa9032a52f930fae6 +
                state[3] *
                0x1e8916a99c93a88e +
                state[4] *
                0xa4911db6a32612da +
                state[5] *
                0x07084430a7307c9a +
                state[6] *
                0xbf150dc4914d380f +
                state[7] *
                0x7fb45d605dd82838 +
                state[8] *
                0x02290fe23c20351a +
                state[9] *
                0xbe2e19f6d07f1a83 +
                state[10] *
                0x4db9a2ead2bd7262 +
                state[11] *
                0x64dd936da878404d;
        }
    }

    function _mdsPartialLayerInit5(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0x3a2432625475e3ae +
                state[2] *
                0x7e33ca8c814280de +
                state[3] *
                0xbba4b5d86b9a3b2c +
                state[4] *
                0x2f7e9aade3fdaec1 +
                state[5] *
                0xad2f570a5b8545aa +
                state[6] *
                0xc26a083554767106 +
                state[7] *
                0x862361aeab0f9b6e +
                state[8] *
                0x7fb45d605dd82838 +
                state[9] *
                0x18737784700c75cd +
                state[10] *
                0x1d7f8a2cce1a9d00 +
                state[11] *
                0x726af914971c1374;
        }
    }

    function _mdsPartialLayerInit6(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0x00a2d4321cca94fe +
                state[2] *
                0xad11180f69a8c29e +
                state[3] *
                0xe76649f9bd5d5c2e +
                state[4] *
                0xe7ffd578da4ea43d +
                state[5] *
                0xab7f81fef4274770 +
                state[6] *
                0x753b8b1126665c22 +
                state[7] *
                0xc26a083554767106 +
                state[8] *
                0xbf150dc4914d380f +
                state[9] *
                0x623708f28fca70e8 +
                state[10] *
                0x4b1ba8d40afca97d +
                state[11] *
                0x7f8e41e0b0a6cdff;
        }
    }

    function _mdsPartialLayerInit7(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0x77736f524010c932 +
                state[2] *
                0xc75ac6d5b5a10ff3 +
                state[3] *
                0xaf8e2518a1ece54d +
                state[4] *
                0x43a608e7afa6b5c2 +
                state[5] *
                0xcb81f535cf98c9e9 +
                state[6] *
                0xab7f81fef4274770 +
                state[7] *
                0xad2f570a5b8545aa +
                state[8] *
                0x07084430a7307c9a +
                state[9] *
                0x5996a80497e24a6b +
                state[10] *
                0x5e40f0c9bb82aab5 +
                state[11] *
                0xf97abba0dffb6c50;
        }
    }

    function _mdsPartialLayerInit8(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0x904d3f2804a36c54 +
                state[2] *
                0xf0674a8dc5a387ec +
                state[3] *
                0xdcda1344cdca873f +
                state[4] *
                0xca46546aa99e1575 +
                state[5] *
                0x43a608e7afa6b5c2 +
                state[6] *
                0xe7ffd578da4ea43d +
                state[7] *
                0x2f7e9aade3fdaec1 +
                state[8] *
                0xa4911db6a32612da +
                state[9] *
                0x7f68007619fd8ba9 +
                state[10] *
                0xc537d44dc2875403 +
                state[11] *
                0xf4a437f2888ae909;
        }
    }

    function _mdsPartialLayerInit9(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0xbf9b39e28a16f354 +
                state[2] *
                0xb36d43120eaa5e2b +
                state[3] *
                0xcd080204256088e5 +
                state[4] *
                0xdcda1344cdca873f +
                state[5] *
                0xaf8e2518a1ece54d +
                state[6] *
                0xe76649f9bd5d5c2e +
                state[7] *
                0xbba4b5d86b9a3b2c +
                state[8] *
                0x1e8916a99c93a88e +
                state[9] *
                0x4715b8e5ab34653b +
                state[10] *
                0x14a4a64da0b2668f +
                state[11] *
                0xdcedab70f40718ba;
        }
    }

    function _mdsPartialLayerInit10(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0x3a1ded54a6cd058b +
                state[2] *
                0x6f232aab4b533a25 +
                state[3] *
                0xb36d43120eaa5e2b +
                state[4] *
                0xf0674a8dc5a387ec +
                state[5] *
                0xc75ac6d5b5a10ff3 +
                state[6] *
                0xad11180f69a8c29e +
                state[7] *
                0x7e33ca8c814280de +
                state[8] *
                0xa9032a52f930fae6 +
                state[9] *
                0x0ee5dc0ce131268a +
                state[10] *
                0xb124c33152a2421a +
                state[11] *
                0xe796d293a47a64cb;
        }
    }

    function _mdsPartialLayerInit11(
        uint256[WIDTH] memory state
    ) private pure returns (uint256 res) {
        unchecked {
            res =
                state[1] *
                0x42392870da5737cf +
                state[2] *
                0x3a1ded54a6cd058b +
                state[3] *
                0xbf9b39e28a16f354 +
                state[4] *
                0x904d3f2804a36c54 +
                state[5] *
                0x77736f524010c932 +
                state[6] *
                0x00a2d4321cca94fe +
                state[7] *
                0x3a2432625475e3ae +
                state[8] *
                0x90e80c591f48b603 +
                state[9] *
                0xc1978156516879ad +
                state[10] *
                0xdc927721da922cf8 +
                state[11] *
                0x80772dc2645b280b;
        }
    }

    // `state[i]` allows 193 bits number.
    // `newState[i]` is 64 bits number.
    function _mdsPartialLayerFast(
        uint256[WIDTH] memory state,
        uint256 r
    ) internal pure returns (uint256[WIDTH] memory newState) {
        unchecked {
            uint256 dSum = state[0] * (MDS_MATRIX_CIRC_0 + MDS_MATRIX_DIAG_0);

            // for (uint256 i = 1; i < 12; i++) {
            //     dSum += state[i] * FAST_PARTIAL_ROUND_W_HATS[r][i - 1];
            // }
            if (r == 0) {
                dSum +=
                    state[1] *
                    0x3d999c961b7c63b0 +
                    state[2] *
                    0x814e82efcd172529 +
                    state[3] *
                    0x2421e5d236704588 +
                    state[4] *
                    0x887af7d4dd482328 +
                    state[5] *
                    0xa5e9c291f6119b27 +
                    state[6] *
                    0xbdc52b2676a4b4aa +
                    state[7] *
                    0x64832009d29bcf57 +
                    state[8] *
                    0x09c4155174a552cc +
                    state[9] *
                    0x463f9ee03d290810 +
                    state[10] *
                    0xc810936e64982542 +
                    state[11] *
                    0x043b1c289f7bc3ac;
                // TODO: Rewrite to reduce gas.
                // newState[0] = mod(dSum);
                // newState[1] = mod(state[1] + state[0] * 0x94877900674181c3);
                // newState[2] = mod(state[2] + state[0] * 0xc6c67cc37a2a2bbd);
                // newState[3] = mod(state[3] + state[0] * 0xd667c2055387940f);
                // newState[4] = mod(state[4] + state[0] * 0x0ba63a63e94b5ff0);
                // newState[5] = mod(state[5] + state[0] * 0x99460cc41b8f079f);
                // newState[6] = mod(state[6] + state[0] * 0x7ff02375ed524bb3);
                // newState[7] = mod(state[7] + state[0] * 0xea0870b47a8caf0e);
                // newState[8] = mod(state[8] + state[0] * 0xabcad82633b7bc9d);
                // newState[9] = mod(state[9] + state[0] * 0x3b8d135261052241);
                // newState[10] = mod(state[10] + state[0] * 0xfb4515f5e5b0d539);
                // newState[11] = mod(state[11] + state[0] * 0x3ee8011c2b37f77c);
                // return newState;
            } else if (r == 1) {
                dSum +=
                    state[1] *
                    0x673655aae8be5a8b +
                    state[2] *
                    0xd510fe714f39fa10 +
                    state[3] *
                    0x2c68a099b51c9e73 +
                    state[4] *
                    0xa667bfa9aa96999d +
                    state[5] *
                    0x4d67e72f063e2108 +
                    state[6] *
                    0xf84dde3e6acda179 +
                    state[7] *
                    0x40f9cc8c08f80981 +
                    state[8] *
                    0x5ead032050097142 +
                    state[9] *
                    0x6591b02092d671bb +
                    state[10] *
                    0x00e18c71963dd1b7 +
                    state[11] *
                    0x8a21bcd24a14218a;
            } else if (r == 2) {
                dSum +=
                    state[1] *
                    0x202800f4addbdc87 +
                    state[2] *
                    0xe4b5bdb1cc3504ff +
                    state[3] *
                    0xbe32b32a825596e7 +
                    state[4] *
                    0x8e0f68c5dc223b9a +
                    state[5] *
                    0x58022d9e1c256ce3 +
                    state[6] *
                    0x584d29227aa073ac +
                    state[7] *
                    0x8b9352ad04bef9e7 +
                    state[8] *
                    0xaead42a3f445ecbf +
                    state[9] *
                    0x3c667a1d833a3cca +
                    state[10] *
                    0xda6f61838efa1ffe +
                    state[11] *
                    0xe8f749470bd7c446;
            } else if (r == 3) {
                dSum +=
                    state[1] *
                    0xc5b85bab9e5b3869 +
                    state[2] *
                    0x45245258aec51cf7 +
                    state[3] *
                    0x16e6b8e68b931830 +
                    state[4] *
                    0xe2ae0f051418112c +
                    state[5] *
                    0x0470e26a0093a65b +
                    state[6] *
                    0x6bef71973a8146ed +
                    state[7] *
                    0x119265be51812daf +
                    state[8] *
                    0xb0be7356254bea2e +
                    state[9] *
                    0x8584defff7589bd7 +
                    state[10] *
                    0x3c5fe4aeb1fb52ba +
                    state[11] *
                    0x9e7cd88acf543a5e;
            } else if (r == 4) {
                dSum +=
                    state[1] *
                    0x179be4bba87f0a8c +
                    state[2] *
                    0xacf63d95d8887355 +
                    state[3] *
                    0x6696670196b0074f +
                    state[4] *
                    0xd99ddf1fe75085f9 +
                    state[5] *
                    0xc2597881fef0283b +
                    state[6] *
                    0xcf48395ee6c54f14 +
                    state[7] *
                    0x15226a8e4cd8d3b6 +
                    state[8] *
                    0xc053297389af5d3b +
                    state[9] *
                    0x2c08893f0d1580e2 +
                    state[10] *
                    0x0ed3cbcff6fcc5ba +
                    state[11] *
                    0xc82f510ecf81f6d0;
            } else if (r == 5) {
                dSum +=
                    state[1] *
                    0x94b06183acb715cc +
                    state[2] *
                    0x500392ed0d431137 +
                    state[3] *
                    0x861cc95ad5c86323 +
                    state[4] *
                    0x05830a443f86c4ac +
                    state[5] *
                    0x3b68225874a20a7c +
                    state[6] *
                    0x10b3309838e236fb +
                    state[7] *
                    0x9b77fc8bcd559e2c +
                    state[8] *
                    0xbdecf5e0cb9cb213 +
                    state[9] *
                    0x30276f1221ace5fa +
                    state[10] *
                    0x7935dd342764a144 +
                    state[11] *
                    0xeac6db520bb03708;
            } else if (r == 6) {
                dSum +=
                    state[1] *
                    0x7186a80551025f8f +
                    state[2] *
                    0x622247557e9b5371 +
                    state[3] *
                    0xc4cbe326d1ad9742 +
                    state[4] *
                    0x55f1523ac6a23ea2 +
                    state[5] *
                    0xa13dfe77a3d52f53 +
                    state[6] *
                    0xe30750b6301c0452 +
                    state[7] *
                    0x08bd488070a3a32b +
                    state[8] *
                    0xcd800caef5b72ae3 +
                    state[9] *
                    0x83329c90f04233ce +
                    state[10] *
                    0xb5b99e6664a0a3ee +
                    state[11] *
                    0x6b0731849e200a7f;
            } else if (r == 7) {
                dSum +=
                    state[1] *
                    0xec3fabc192b01799 +
                    state[2] *
                    0x382b38cee8ee5375 +
                    state[3] *
                    0x3bfb6c3f0e616572 +
                    state[4] *
                    0x514abd0cf6c7bc86 +
                    state[5] *
                    0x47521b1361dcc546 +
                    state[6] *
                    0x178093843f863d14 +
                    state[7] *
                    0xad1003c5d28918e7 +
                    state[8] *
                    0x738450e42495bc81 +
                    state[9] *
                    0xaf947c59af5e4047 +
                    state[10] *
                    0x4653fb0685084ef2 +
                    state[11] *
                    0x057fde2062ae35bf;
            } else if (r == 8) {
                dSum +=
                    state[1] *
                    0xe376678d843ce55e +
                    state[2] *
                    0x66f3860d7514e7fc +
                    state[3] *
                    0x7817f3dfff8b4ffa +
                    state[4] *
                    0x3929624a9def725b +
                    state[5] *
                    0x0126ca37f215a80a +
                    state[6] *
                    0xfce2f5d02762a303 +
                    state[7] *
                    0x1bc927375febbad7 +
                    state[8] *
                    0x85b481e5243f60bf +
                    state[9] *
                    0x2d3c5f42a39c91a0 +
                    state[10] *
                    0x0811719919351ae8 +
                    state[11] *
                    0xf669de0add993131;
            } else if (r == 9) {
                dSum +=
                    state[1] *
                    0x7de38bae084da92d +
                    state[2] *
                    0x5b848442237e8a9b +
                    state[3] *
                    0xf6c705da84d57310 +
                    state[4] *
                    0x31e6a4bdb6a49017 +
                    state[5] *
                    0x889489706e5c5c0f +
                    state[6] *
                    0x0e4a205459692a1b +
                    state[7] *
                    0xbac3fa75ee26f299 +
                    state[8] *
                    0x5f5894f4057d755e +
                    state[9] *
                    0xb0dc3ecd724bb076 +
                    state[10] *
                    0x5e34d8554a6452ba +
                    state[11] *
                    0x04f78fd8c1fdcc5f;
            } else if (r == 10) {
                dSum +=
                    state[1] *
                    0x4dd19c38779512ea +
                    state[2] *
                    0xdb79ba02704620e9 +
                    state[3] *
                    0x92a29a3675a5d2be +
                    state[4] *
                    0xd5177029fe495166 +
                    state[5] *
                    0xd32b3298a13330c1 +
                    state[6] *
                    0x251c4a3eb2c5f8fd +
                    state[7] *
                    0xe1c48b26e0d98825 +
                    state[8] *
                    0x3301d3362a4ffccb +
                    state[9] *
                    0x09bb6c88de8cd178 +
                    state[10] *
                    0xdc05b676564f538a +
                    state[11] *
                    0x60192d883e473fee;
            } else if (r == 11) {
                dSum +=
                    state[1] *
                    0x16b9774801ac44a0 +
                    state[2] *
                    0x3cb8411e786d3c8e +
                    state[3] *
                    0xa86e9cf505072491 +
                    state[4] *
                    0x0178928152e109ae +
                    state[5] *
                    0x5317b905a6e1ab7b +
                    state[6] *
                    0xda20b3be7f53d59f +
                    state[7] *
                    0xcb97dedecebee9ad +
                    state[8] *
                    0x4bd545218c59f58d +
                    state[9] *
                    0x77dc8d856c05a44a +
                    state[10] *
                    0x87948589e4f243fd +
                    state[11] *
                    0x7e5217af969952c2;
            } else if (r == 12) {
                dSum +=
                    state[1] *
                    0xbc58987d06a84e4d +
                    state[2] *
                    0x0b5d420244c9cae3 +
                    state[3] *
                    0xa3c4711b938c02c0 +
                    state[4] *
                    0x3aace640a3e03990 +
                    state[5] *
                    0x865a0f3249aacd8a +
                    state[6] *
                    0x8d00b2a7dbed06c7 +
                    state[7] *
                    0x6eacb905beb7e2f8 +
                    state[8] *
                    0x045322b216ec3ec7 +
                    state[9] *
                    0xeb9de00d594828e6 +
                    state[10] *
                    0x088c5f20df9e5c26 +
                    state[11] *
                    0xf555f4112b19781f;
            } else if (r == 13) {
                dSum +=
                    state[1] *
                    0xa8cedbff1813d3a7 +
                    state[2] *
                    0x50dcaee0fd27d164 +
                    state[3] *
                    0xf1cb02417e23bd82 +
                    state[4] *
                    0xfaf322786e2abe8b +
                    state[5] *
                    0x937a4315beb5d9b6 +
                    state[6] *
                    0x1b18992921a11d85 +
                    state[7] *
                    0x7d66c4368b3c497b +
                    state[8] *
                    0x0e7946317a6b4e99 +
                    state[9] *
                    0xbe4430134182978b +
                    state[10] *
                    0x3771e82493ab262d +
                    state[11] *
                    0xa671690d8095ce82;
            } else if (r == 14) {
                dSum +=
                    state[1] *
                    0xb035585f6e929d9d +
                    state[2] *
                    0xba1579c7e219b954 +
                    state[3] *
                    0xcb201cf846db4ba3 +
                    state[4] *
                    0x287bf9177372cf45 +
                    state[5] *
                    0xa350e4f61147d0a6 +
                    state[6] *
                    0xd5d0ecfb50bcff99 +
                    state[7] *
                    0x2e166aa6c776ed21 +
                    state[8] *
                    0xe1e66c991990e282 +
                    state[9] *
                    0x662b329b01e7bb38 +
                    state[10] *
                    0x8aa674b36144d9a9 +
                    state[11] *
                    0xcbabf78f97f95e65;
            } else if (r == 15) {
                dSum +=
                    state[1] *
                    0xeec24b15a06b53fe +
                    state[2] *
                    0xc8a7aa07c5633533 +
                    state[3] *
                    0xefe9c6fa4311ad51 +
                    state[4] *
                    0xb9173f13977109a1 +
                    state[5] *
                    0x69ce43c9cc94aedc +
                    state[6] *
                    0xecf623c9cd118815 +
                    state[7] *
                    0x28625def198c33c7 +
                    state[8] *
                    0xccfc5f7de5c3636a +
                    state[9] *
                    0xf5e6c40f1621c299 +
                    state[10] *
                    0xcec0e58c34cb64b1 +
                    state[11] *
                    0xa868ea113387939f;
            } else if (r == 16) {
                dSum +=
                    state[1] *
                    0xd8dddbdc5ce4ef45 +
                    state[2] *
                    0xacfc51de8131458c +
                    state[3] *
                    0x146bb3c0fe499ac0 +
                    state[4] *
                    0x9e65309f15943903 +
                    state[5] *
                    0x80d0ad980773aa70 +
                    state[6] *
                    0xf97817d4ddbf0607 +
                    state[7] *
                    0xe4626620a75ba276 +
                    state[8] *
                    0x0dfdc7fd6fc74f66 +
                    state[9] *
                    0xf464864ad6f2bb93 +
                    state[10] *
                    0x02d55e52a5d44414 +
                    state[11] *
                    0xdd8de62487c40925;
            } else if (r == 17) {
                dSum +=
                    state[1] *
                    0xc15acf44759545a3 +
                    state[2] *
                    0xcbfdcf39869719d4 +
                    state[3] *
                    0x33f62042e2f80225 +
                    state[4] *
                    0x2599c5ead81d8fa3 +
                    state[5] *
                    0x0b306cb6c1d7c8d0 +
                    state[6] *
                    0x658c80d3df3729b1 +
                    state[7] *
                    0xe8d1b2b21b41429c +
                    state[8] *
                    0xa1b67f09d4b3ccb8 +
                    state[9] *
                    0x0e1adf8b84437180 +
                    state[10] *
                    0x0d593a5e584af47b +
                    state[11] *
                    0xa023d94c56e151c7;
            } else if (r == 18) {
                dSum +=
                    state[1] *
                    0x49026cc3a4afc5a6 +
                    state[2] *
                    0xe06dff00ab25b91b +
                    state[3] *
                    0x0ab38c561e8850ff +
                    state[4] *
                    0x92c3c8275e105eeb +
                    state[5] *
                    0xb65256e546889bd0 +
                    state[6] *
                    0x3c0468236ea142f6 +
                    state[7] *
                    0xee61766b889e18f2 +
                    state[8] *
                    0xa206f41b12c30415 +
                    state[9] *
                    0x02fe9d756c9f12d1 +
                    state[10] *
                    0xe9633210630cbf12 +
                    state[11] *
                    0x1ffea9fe85a0b0b1;
            } else if (r == 19) {
                dSum +=
                    state[1] *
                    0x81d1ae8cc50240f3 +
                    state[2] *
                    0xf4c77a079a4607d7 +
                    state[3] *
                    0xed446b2315e3efc1 +
                    state[4] *
                    0x0b0a6b70915178c3 +
                    state[5] *
                    0xb11ff3e089f15d9a +
                    state[6] *
                    0x1d4dba0b7ae9cc18 +
                    state[7] *
                    0x65d74e2f43b48d05 +
                    state[8] *
                    0xa2df8c6b8ae0804a +
                    state[9] *
                    0xa4e6f0a8c33348a6 +
                    state[10] *
                    0xc0a26efc7be5669b +
                    state[11] *
                    0xa6b6582c547d0d60;
            } else if (r == 20) {
                dSum +=
                    state[1] *
                    0x84afc741f1c13213 +
                    state[2] *
                    0x2f8f43734fc906f3 +
                    state[3] *
                    0xde682d72da0a02d9 +
                    state[4] *
                    0x0bb005236adb9ef2 +
                    state[5] *
                    0x5bdf35c10a8b5624 +
                    state[6] *
                    0x0739a8a343950010 +
                    state[7] *
                    0x52f515f44785cfbc +
                    state[8] *
                    0xcbaf4e5d82856c60 +
                    state[9] *
                    0xac9ea09074e3e150 +
                    state[10] *
                    0x8f0fa011a2035fb0 +
                    state[11] *
                    0x1a37905d8450904a;
            } else if (r == 21) {
                dSum +=
                    state[1] *
                    0x3abeb80def61cc85 +
                    state[2] *
                    0x9d19c9dd4eac4133 +
                    state[3] *
                    0x075a652d9641a985 +
                    state[4] *
                    0x9daf69ae1b67e667 +
                    state[5] *
                    0x364f71da77920a18 +
                    state[6] *
                    0x50bd769f745c95b1 +
                    state[7] *
                    0xf223d1180dbbf3fc +
                    state[8] *
                    0x2f885e584e04aa99 +
                    state[9] *
                    0xb69a0fa70aea684a +
                    state[10] *
                    0x09584acaa6e062a0 +
                    state[11] *
                    0x0bc051640145b19b;
            }

            newState[0] = mod(dSum);

            // for (uint256 i = 1; i < 12; i++)  {
            //     newState[i] = mod(state[i] + state[0] * FAST_PARTIAL_ROUND_VS[r][i - 1]);
            // }
            if (r == 0) {
                newState[1] = mod(state[1] + state[0] * 0x94877900674181c3);
                newState[2] = mod(state[2] + state[0] * 0xc6c67cc37a2a2bbd);
                newState[3] = mod(state[3] + state[0] * 0xd667c2055387940f);
                newState[4] = mod(state[4] + state[0] * 0x0ba63a63e94b5ff0);
                newState[5] = mod(state[5] + state[0] * 0x99460cc41b8f079f);
                newState[6] = mod(state[6] + state[0] * 0x7ff02375ed524bb3);
                newState[7] = mod(state[7] + state[0] * 0xea0870b47a8caf0e);
                newState[8] = mod(state[8] + state[0] * 0xabcad82633b7bc9d);
                newState[9] = mod(state[9] + state[0] * 0x3b8d135261052241);
                newState[10] = mod(state[10] + state[0] * 0xfb4515f5e5b0d539);
                newState[11] = mod(state[11] + state[0] * 0x3ee8011c2b37f77c);
            } else if (r == 1) {
                newState[1] = mod(state[1] + state[0] * 0x0adef3740e71c726);
                newState[2] = mod(state[2] + state[0] * 0xa37bf67c6f986559);
                newState[3] = mod(state[3] + state[0] * 0xc6b16f7ed4fa1b00);
                newState[4] = mod(state[4] + state[0] * 0x6a065da88d8bfc3c);
                newState[5] = mod(state[5] + state[0] * 0x4cabc0916844b46f);
                newState[6] = mod(state[6] + state[0] * 0x407faac0f02e78d1);
                newState[7] = mod(state[7] + state[0] * 0x07a786d9cf0852cf);
                newState[8] = mod(state[8] + state[0] * 0x42433fb6949a629a);
                newState[9] = mod(state[9] + state[0] * 0x891682a147ce43b0);
                newState[10] = mod(state[10] + state[0] * 0x26cfd58e7b003b55);
                newState[11] = mod(state[11] + state[0] * 0x2bbf0ed7b657acb3);
            } else if (r == 2) {
                newState[1] = mod(state[1] + state[0] * 0x481ac7746b159c67);
                newState[2] = mod(state[2] + state[0] * 0xe367de32f108e278);
                newState[3] = mod(state[3] + state[0] * 0x73f260087ad28bec);
                newState[4] = mod(state[4] + state[0] * 0x5cfc82216bc1bdca);
                newState[5] = mod(state[5] + state[0] * 0xcaccc870a2663a0e);
                newState[6] = mod(state[6] + state[0] * 0xdb69cd7b4298c45d);
                newState[7] = mod(state[7] + state[0] * 0x7bc9e0c57243e62d);
                newState[8] = mod(state[8] + state[0] * 0x3cc51c5d368693ae);
                newState[9] = mod(state[9] + state[0] * 0x366b4e8cc068895b);
                newState[10] = mod(state[10] + state[0] * 0x2bd18715cdabbca4);
                newState[11] = mod(state[11] + state[0] * 0xa752061c4f33b8cf);
            } else if (r == 3) {
                newState[1] = mod(state[1] + state[0] * 0xb22d2432b72d5098);
                newState[2] = mod(state[2] + state[0] * 0x9e18a487f44d2fe4);
                newState[3] = mod(state[3] + state[0] * 0x4b39e14ce22abd3c);
                newState[4] = mod(state[4] + state[0] * 0x9e77fde2eb315e0d);
                newState[5] = mod(state[5] + state[0] * 0xca5e0385fe67014d);
                newState[6] = mod(state[6] + state[0] * 0x0c2cb99bf1b6bddb);
                newState[7] = mod(state[7] + state[0] * 0x99ec1cd2a4460bfe);
                newState[8] = mod(state[8] + state[0] * 0x8577a815a2ff843f);
                newState[9] = mod(state[9] + state[0] * 0x7d80a6b4fd6518a5);
                newState[10] = mod(state[10] + state[0] * 0xeb6c67123eab62cb);
                newState[11] = mod(state[11] + state[0] * 0x8f7851650eca21a5);
            } else if (r == 4) {
                newState[1] = mod(state[1] + state[0] * 0x11ba9a1b81718c2a);
                newState[2] = mod(state[2] + state[0] * 0x9f7d798a3323410c);
                newState[3] = mod(state[3] + state[0] * 0xa821855c8c1cf5e5);
                newState[4] = mod(state[4] + state[0] * 0x535e8d6fac0031b2);
                newState[5] = mod(state[5] + state[0] * 0x404e7c751b634320);
                newState[6] = mod(state[6] + state[0] * 0xa729353f6e55d354);
                newState[7] = mod(state[7] + state[0] * 0x4db97d92e58bb831);
                newState[8] = mod(state[8] + state[0] * 0xb53926c27897bf7d);
                newState[9] = mod(state[9] + state[0] * 0x965040d52fe115c5);
                newState[10] = mod(state[10] + state[0] * 0x9565fa41ebd31fd7);
                newState[11] = mod(state[11] + state[0] * 0xaae4438c877ea8f4);
            } else if (r == 5) {
                newState[1] = mod(state[1] + state[0] * 0x37f4e36af6073c6e);
                newState[2] = mod(state[2] + state[0] * 0x4edc0918210800e9);
                newState[3] = mod(state[3] + state[0] * 0xc44998e99eae4188);
                newState[4] = mod(state[4] + state[0] * 0x9f4310d05d068338);
                newState[5] = mod(state[5] + state[0] * 0x9ec7fe4350680f29);
                newState[6] = mod(state[6] + state[0] * 0xc5b2c1fdc0b50874);
                newState[7] = mod(state[7] + state[0] * 0xa01920c5ef8b2ebe);
                newState[8] = mod(state[8] + state[0] * 0x59fa6f8bd91d58ba);
                newState[9] = mod(state[9] + state[0] * 0x8bfc9eb89b515a82);
                newState[10] = mod(state[10] + state[0] * 0xbe86a7a2555ae775);
                newState[11] = mod(state[11] + state[0] * 0xcbb8bbaa3810babf);
            } else if (r == 6) {
                newState[1] = mod(state[1] + state[0] * 0x577f9a9e7ee3f9c2);
                newState[2] = mod(state[2] + state[0] * 0x88c522b949ace7b1);
                newState[3] = mod(state[3] + state[0] * 0x82f07007c8b72106);
                newState[4] = mod(state[4] + state[0] * 0x8283d37c6675b50e);
                newState[5] = mod(state[5] + state[0] * 0x98b074d9bbac1123);
                newState[6] = mod(state[6] + state[0] * 0x75c56fb7758317c1);
                newState[7] = mod(state[7] + state[0] * 0xfed24e206052bc72);
                newState[8] = mod(state[8] + state[0] * 0x26d7c3d1bc07dae5);
                newState[9] = mod(state[9] + state[0] * 0xf88c5e441e28dbb4);
                newState[10] = mod(state[10] + state[0] * 0x4fe27f9f96615270);
                newState[11] = mod(state[11] + state[0] * 0x514d4ba49c2b14fe);
            } else if (r == 7) {
                newState[1] = mod(state[1] + state[0] * 0xf02a3ac068ee110b);
                newState[2] = mod(state[2] + state[0] * 0x0a3630dafb8ae2d7);
                newState[3] = mod(state[3] + state[0] * 0xce0dc874eaf9b55c);
                newState[4] = mod(state[4] + state[0] * 0x9a95f6cff5b55c7e);
                newState[5] = mod(state[5] + state[0] * 0x626d76abfed00c7b);
                newState[6] = mod(state[6] + state[0] * 0xa0c1cf1251c204ad);
                newState[7] = mod(state[7] + state[0] * 0xdaebd3006321052c);
                newState[8] = mod(state[8] + state[0] * 0x3d4bd48b625a8065);
                newState[9] = mod(state[9] + state[0] * 0x7f1e584e071f6ed2);
                newState[10] = mod(state[10] + state[0] * 0x720574f0501caed3);
                newState[11] = mod(state[11] + state[0] * 0xe3260ba93d23540a);
            } else if (r == 8) {
                newState[1] = mod(state[1] + state[0] * 0xab1cbd41d8c1e335);
                newState[2] = mod(state[2] + state[0] * 0x9322ed4c0bc2df01);
                newState[3] = mod(state[3] + state[0] * 0x51c3c0983d4284e5);
                newState[4] = mod(state[4] + state[0] * 0x94178e291145c231);
                newState[5] = mod(state[5] + state[0] * 0xfd0f1a973d6b2085);
                newState[6] = mod(state[6] + state[0] * 0xd427ad96e2b39719);
                newState[7] = mod(state[7] + state[0] * 0x8a52437fecaac06b);
                newState[8] = mod(state[8] + state[0] * 0xdc20ee4b8c4c9a80);
                newState[9] = mod(state[9] + state[0] * 0xa2c98e9549da2100);
                newState[10] = mod(state[10] + state[0] * 0x1603fe12613db5b6);
                newState[11] = mod(state[11] + state[0] * 0x0e174929433c5505);
            } else if (r == 9) {
                newState[1] = mod(state[1] + state[0] * 0x3d4eab2b8ef5f796);
                newState[2] = mod(state[2] + state[0] * 0xcfff421583896e22);
                newState[3] = mod(state[3] + state[0] * 0x4143cb32d39ac3d9);
                newState[4] = mod(state[4] + state[0] * 0x22365051b78a5b65);
                newState[5] = mod(state[5] + state[0] * 0x6f7fd010d027c9b6);
                newState[6] = mod(state[6] + state[0] * 0xd9dd36fba77522ab);
                newState[7] = mod(state[7] + state[0] * 0xa44cf1cb33e37165);
                newState[8] = mod(state[8] + state[0] * 0x3fc83d3038c86417);
                newState[9] = mod(state[9] + state[0] * 0xc4588d418e88d270);
                newState[10] = mod(state[10] + state[0] * 0xce1320f10ab80fe2);
                newState[11] = mod(state[11] + state[0] * 0xdb5eadbbec18de5d);
            } else if (r == 10) {
                newState[1] = mod(state[1] + state[0] * 0x1183dfce7c454afd);
                newState[2] = mod(state[2] + state[0] * 0x21cea4aa3d3ed949);
                newState[3] = mod(state[3] + state[0] * 0x0fce6f70303f2304);
                newState[4] = mod(state[4] + state[0] * 0x19557d34b55551be);
                newState[5] = mod(state[5] + state[0] * 0x4c56f689afc5bbc9);
                newState[6] = mod(state[6] + state[0] * 0xa1e920844334f944);
                newState[7] = mod(state[7] + state[0] * 0xbad66d423d2ec861);
                newState[8] = mod(state[8] + state[0] * 0xf318c785dc9e0479);
                newState[9] = mod(state[9] + state[0] * 0x99e2032e765ddd81);
                newState[10] = mod(state[10] + state[0] * 0x400ccc9906d66f45);
                newState[11] = mod(state[11] + state[0] * 0xe1197454db2e0dd9);
            } else if (r == 11) {
                newState[1] = mod(state[1] + state[0] * 0x84d1ecc4d53d2ff1);
                newState[2] = mod(state[2] + state[0] * 0xd8af8b9ceb4e11b6);
                newState[3] = mod(state[3] + state[0] * 0x335856bb527b52f4);
                newState[4] = mod(state[4] + state[0] * 0xc756f17fb59be595);
                newState[5] = mod(state[5] + state[0] * 0xc0654e4ea5553a78);
                newState[6] = mod(state[6] + state[0] * 0x9e9a46b61f2ea942);
                newState[7] = mod(state[7] + state[0] * 0x14fc8b5b3b809127);
                newState[8] = mod(state[8] + state[0] * 0xd7009f0f103be413);
                newState[9] = mod(state[9] + state[0] * 0x3e0ee7b7a9fb4601);
                newState[10] = mod(state[10] + state[0] * 0xa74e888922085ed7);
                newState[11] = mod(state[11] + state[0] * 0xe80a7cde3d4ac526);
            } else if (r == 12) {
                newState[1] = mod(state[1] + state[0] * 0x238aa6daa612186d);
                newState[2] = mod(state[2] + state[0] * 0x9137a5c630bad4b4);
                newState[3] = mod(state[3] + state[0] * 0xc7db3817870c5eda);
                newState[4] = mod(state[4] + state[0] * 0x217e4f04e5718dc9);
                newState[5] = mod(state[5] + state[0] * 0xcae814e2817bd99d);
                newState[6] = mod(state[6] + state[0] * 0xe3292e7ab770a8ba);
                newState[7] = mod(state[7] + state[0] * 0x7bb36ef70b6b9482);
                newState[8] = mod(state[8] + state[0] * 0x3c7835fb85bca2d3);
                newState[9] = mod(state[9] + state[0] * 0xfe2cdf8ee3c25e86);
                newState[10] = mod(state[10] + state[0] * 0x61b3915ad7274b20);
                newState[11] = mod(state[11] + state[0] * 0xeab75ca7c918e4ef);
            } else if (r == 13) {
                newState[1] = mod(state[1] + state[0] * 0xd6e15ffc055e154e);
                newState[2] = mod(state[2] + state[0] * 0xec67881f381a32bf);
                newState[3] = mod(state[3] + state[0] * 0xfbb1196092bf409c);
                newState[4] = mod(state[4] + state[0] * 0xdc9d2e07830ba226);
                newState[5] = mod(state[5] + state[0] * 0x0698ef3245ff7988);
                newState[6] = mod(state[6] + state[0] * 0x194fae2974f8b576);
                newState[7] = mod(state[7] + state[0] * 0x7a5d9bea6ca4910e);
                newState[8] = mod(state[8] + state[0] * 0x7aebfea95ccdd1c9);
                newState[9] = mod(state[9] + state[0] * 0xf9bd38a67d5f0e86);
                newState[10] = mod(state[10] + state[0] * 0xfa65539de65492d8);
                newState[11] = mod(state[11] + state[0] * 0xf0dfcbe7653ff787);
            } else if (r == 14) {
                newState[1] = mod(state[1] + state[0] * 0x0bd87ad390420258);
                newState[2] = mod(state[2] + state[0] * 0x0ad8617bca9e33c8);
                newState[3] = mod(state[3] + state[0] * 0x0c00ad377a1e2666);
                newState[4] = mod(state[4] + state[0] * 0x0ac6fc58b3f0518f);
                newState[5] = mod(state[5] + state[0] * 0x0c0cc8a892cc4173);
                newState[6] = mod(state[6] + state[0] * 0x0c210accb117bc21);
                newState[7] = mod(state[7] + state[0] * 0x0b73630dbb46ca18);
                newState[8] = mod(state[8] + state[0] * 0x0c8be4920cbd4a54);
                newState[9] = mod(state[9] + state[0] * 0x0bfe877a21be1690);
                newState[10] = mod(state[10] + state[0] * 0x0ae790559b0ded81);
                newState[11] = mod(state[11] + state[0] * 0x0bf50db2f8d6ce31);
            } else if (r == 15) {
                newState[1] = mod(state[1] + state[0] * 0x000cf29427ff7c58);
                newState[2] = mod(state[2] + state[0] * 0x000bd9b3cf49eec8);
                newState[3] = mod(state[3] + state[0] * 0x000d1dc8aa81fb26);
                newState[4] = mod(state[4] + state[0] * 0x000bc792d5c394ef);
                newState[5] = mod(state[5] + state[0] * 0x000d2ae0b2266453);
                newState[6] = mod(state[6] + state[0] * 0x000d413f12c496c1);
                newState[7] = mod(state[7] + state[0] * 0x000c84128cfed618);
                newState[8] = mod(state[8] + state[0] * 0x000db5ebd48fc0d4);
                newState[9] = mod(state[9] + state[0] * 0x000d1b77326dcb90);
                newState[10] = mod(state[10] + state[0] * 0x000beb0ccc145421);
                newState[11] = mod(state[11] + state[0] * 0x000d10e5b22b11d1);
            } else if (r == 16) {
                newState[1] = mod(state[1] + state[0] * 0x00000e24c99adad8);
                newState[2] = mod(state[2] + state[0] * 0x00000cf389ed4bc8);
                newState[3] = mod(state[3] + state[0] * 0x00000e580cbf6966);
                newState[4] = mod(state[4] + state[0] * 0x00000cde5fd7e04f);
                newState[5] = mod(state[5] + state[0] * 0x00000e63628041b3);
                newState[6] = mod(state[6] + state[0] * 0x00000e7e81a87361);
                newState[7] = mod(state[7] + state[0] * 0x00000dabe78f6d98);
                newState[8] = mod(state[8] + state[0] * 0x00000efb14cac554);
                newState[9] = mod(state[9] + state[0] * 0x00000e5574743b10);
                newState[10] = mod(state[10] + state[0] * 0x00000d05709f42c1);
                newState[11] = mod(state[11] + state[0] * 0x00000e4690c96af1);
            } else if (r == 17) {
                newState[1] = mod(state[1] + state[0] * 0x0000000f7157bc98);
                newState[2] = mod(state[2] + state[0] * 0x0000000e3006d948);
                newState[3] = mod(state[3] + state[0] * 0x0000000fa65811e6);
                newState[4] = mod(state[4] + state[0] * 0x0000000e0d127e2f);
                newState[5] = mod(state[5] + state[0] * 0x0000000fc18bfe53);
                newState[6] = mod(state[6] + state[0] * 0x0000000fd002d901);
                newState[7] = mod(state[7] + state[0] * 0x0000000eed6461d8);
                newState[8] = mod(state[8] + state[0] * 0x0000001068562754);
                newState[9] = mod(state[9] + state[0] * 0x0000000fa0236f50);
                newState[10] = mod(state[10] + state[0] * 0x0000000e3af13ee1);
                newState[11] = mod(state[11] + state[0] * 0x0000000fa460f6d1);
            } else if (r == 18) {
                newState[1] = mod(state[1] + state[0] * 0x0000000011131738);
                newState[2] = mod(state[2] + state[0] * 0x000000000f56d588);
                newState[3] = mod(state[3] + state[0] * 0x0000000011050f86);
                newState[4] = mod(state[4] + state[0] * 0x000000000f848f4f);
                newState[5] = mod(state[5] + state[0] * 0x00000000111527d3);
                newState[6] = mod(state[6] + state[0] * 0x00000000114369a1);
                newState[7] = mod(state[7] + state[0] * 0x00000000106f2f38);
                newState[8] = mod(state[8] + state[0] * 0x0000000011e2ca94);
                newState[9] = mod(state[9] + state[0] * 0x00000000110a29f0);
                newState[10] = mod(state[10] + state[0] * 0x000000000fa9f5c1);
                newState[11] = mod(state[11] + state[0] * 0x0000000010f625d1);
            } else if (r == 19) {
                newState[1] = mod(state[1] + state[0] * 0x000000000011f718);
                newState[2] = mod(state[2] + state[0] * 0x000000000010b6c8);
                newState[3] = mod(state[3] + state[0] * 0x0000000000134a96);
                newState[4] = mod(state[4] + state[0] * 0x000000000010cf7f);
                newState[5] = mod(state[5] + state[0] * 0x0000000000124d03);
                newState[6] = mod(state[6] + state[0] * 0x000000000013f8a1);
                newState[7] = mod(state[7] + state[0] * 0x0000000000117c58);
                newState[8] = mod(state[8] + state[0] * 0x0000000000132c94);
                newState[9] = mod(state[9] + state[0] * 0x0000000000134fc0);
                newState[10] = mod(state[10] + state[0] * 0x000000000010a091);
                newState[11] = mod(state[11] + state[0] * 0x0000000000128961);
            } else if (r == 20) {
                newState[1] = mod(state[1] + state[0] * 0x0000000000001300);
                newState[2] = mod(state[2] + state[0] * 0x0000000000001750);
                newState[3] = mod(state[3] + state[0] * 0x000000000000114e);
                newState[4] = mod(state[4] + state[0] * 0x000000000000131f);
                newState[5] = mod(state[5] + state[0] * 0x000000000000167b);
                newState[6] = mod(state[6] + state[0] * 0x0000000000001371);
                newState[7] = mod(state[7] + state[0] * 0x0000000000001230);
                newState[8] = mod(state[8] + state[0] * 0x000000000000182c);
                newState[9] = mod(state[9] + state[0] * 0x0000000000001368);
                newState[10] = mod(state[10] + state[0] * 0x0000000000000f31);
                newState[11] = mod(state[11] + state[0] * 0x00000000000015c9);
            } else if (r == 21) {
                newState[1] = mod(state[1] + state[0] * 0x0000000000000014);
                newState[2] = mod(state[2] + state[0] * 0x0000000000000022);
                newState[3] = mod(state[3] + state[0] * 0x0000000000000012);
                newState[4] = mod(state[4] + state[0] * 0x0000000000000027);
                newState[5] = mod(state[5] + state[0] * 0x000000000000000d);
                newState[6] = mod(state[6] + state[0] * 0x000000000000000d);
                newState[7] = mod(state[7] + state[0] * 0x000000000000001c);
                newState[8] = mod(state[8] + state[0] * 0x0000000000000002);
                newState[9] = mod(state[9] + state[0] * 0x0000000000000010);
                newState[10] = mod(state[10] + state[0] * 0x0000000000000029);
                newState[11] = mod(state[11] + state[0] * 0x000000000000000f);
            }
        }
    }

    function _partialFirstLayer(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256[WIDTH] memory newState) {
        // _partial_first_constantLayer
        // for (uint256 i = 0; i < 12; i++) {
        //     newState[i] = add(state[i], FAST_PARTIAL_FIRST_ROUND_CONSTANT[i]);
        // }
        state[1] = add(state[1], FAST_PARTIAL_FIRST_ROUND_CONSTANT_1);
        state[2] = add(state[2], FAST_PARTIAL_FIRST_ROUND_CONSTANT_2);
        state[3] = add(state[3], FAST_PARTIAL_FIRST_ROUND_CONSTANT_3);
        state[4] = add(state[4], FAST_PARTIAL_FIRST_ROUND_CONSTANT_4);
        state[5] = add(state[5], FAST_PARTIAL_FIRST_ROUND_CONSTANT_5);
        state[6] = add(state[6], FAST_PARTIAL_FIRST_ROUND_CONSTANT_6);
        state[7] = add(state[7], FAST_PARTIAL_FIRST_ROUND_CONSTANT_7);
        state[8] = add(state[8], FAST_PARTIAL_FIRST_ROUND_CONSTANT_8);
        state[9] = add(state[9], FAST_PARTIAL_FIRST_ROUND_CONSTANT_9);
        state[10] = add(state[10], FAST_PARTIAL_FIRST_ROUND_CONSTANT_10);
        state[11] = add(state[11], FAST_PARTIAL_FIRST_ROUND_CONSTANT_11);
        // state[0] = add(state[0], FAST_PARTIAL_FIRST_ROUND_CONSTANT_0);

        // _mds_partial_layer_init
        // for (uint256 c = 1; c < WIDTH; c++) {
        //     for (uint256 r = 0; r < WIDTH; r++) {
        //         newState[c] += state[r] * FAST_PARTIAL_ROUND_INITIAL_MATRIX[r - 1][c - 1];
        //     }
        // }
        newState[1] = _mdsPartialLayerInit1(state);
        uint256 res = _mdsPartialLayerInit3(state);
        newState[3] = res;
        newState[4] = _mdsPartialLayerInit4(state);
        newState[5] = _mdsPartialLayerInit5(state);
        newState[6] = _mdsPartialLayerInit6(state);
        newState[7] = _mdsPartialLayerInit7(state);
        newState[8] = _mdsPartialLayerInit8(state);
        newState[9] = _mdsPartialLayerInit9(state);
        newState[10] = _mdsPartialLayerInit10(state);
        newState[11] = _mdsPartialLayerInit11(state);
        newState[2] = _mdsPartialLayerInit2(state);
        newState[0] = add(state[0], FAST_PARTIAL_FIRST_ROUND_CONSTANT_0);
    }

    function _getRoundConstant(
        uint256 index
    ) private pure returns (uint256 roundConstant) {
        if (index < 48) {
            if (index < 24) {
                if (index < 12) {
                    if (index < 4) {
                        if (index < 2) {
                            if (index == 0) return 0xb585f766f2144405;
                            /* if (index == 1) */ return 0x7746a55f43921ad7;
                        }
                        if (index == 2) return 0xb2fb0d31cee799b4;
                        /* if (index == 3) */ return 0x0f6760a4803427d7;
                    }
                    if (index < 8) {
                        if (index < 6) {
                            if (index == 4) return 0xe10d666650f4e012;
                            /* if (index == 5) */ return 0x8cae14cb07d09bf1;
                        }
                        if (index == 6) return 0xd438539c95f63e9f;
                        /* if (index == 7) */ return 0xef781c7ce35b4c3d;
                    }
                    if (index < 10) {
                        if (index == 8) return 0xcdc4a239b0c44426;
                        /* if (index == 9) */ return 0x277fa208bf337bff;
                    }
                    if (index == 10) return 0xe17653a29da578a1;
                    /* if (index == 11) */ return 0xc54302f225db2c76;
                }
                if (index < 16) {
                    if (index < 14) {
                        if (index == 12) return 0x86287821f722c881;
                        /* if (index == 13) */ return 0x59cd1a8a41c18e55;
                    }
                    if (index == 14) return 0xc3b919ad495dc574;
                    /* if (index == 15) */ return 0xa484c4c5ef6a0781;
                }
                if (index < 20) {
                    if (index < 18) {
                        if (index == 16) return 0x308bbd23dc5416cc;
                        /* if (index == 17) */ return 0x6e4a40c18f30c09c;
                    }
                    if (index == 18) return 0x9a2eedb70d8f8cfa;
                    /* if (index == 19) */ return 0xe360c6e0ae486f38;
                }
                if (index < 22) {
                    if (index == 20) return 0xd5c7718fbfc647fb;
                    /* if (index == 21) */ return 0xc35eae071903ff0b;
                }
                if (index == 22) return 0x849c2656969c4be7;
                /* if (index == 23) */ return 0xc0572c8c08cbbbad;
            }
            if (index < 36) {
                if (index < 28) {
                    if (index < 26) {
                        if (index == 24) return 0xe9fa634a21de0082;
                        /* if (index == 25) */ return 0xf56f6d48959a600d;
                    }
                    if (index == 26) return 0xf7d713e806391165;
                    /* if (index == 27) */ return 0x8297132b32825daf;
                }
                if (index < 32) {
                    if (index < 30) {
                        if (index == 28) return 0xad6805e0e30b2c8a;
                        /* if (index == 29) */ return 0xac51d9f5fcf8535e;
                    }
                    if (index == 30) return 0x502ad7dc18c2ad87;
                    /* if (index == 31) */ return 0x57a1550c110b3041;
                }
                if (index < 34) {
                    if (index == 32) return 0x66bbd30e6ce0e583;
                    /* if (index == 33) */ return 0x0da2abef589d644e;
                }
                if (index == 34) return 0xf061274fdb150d61;
                /* if (index == 35) */ return 0x28b8ec3ae9c29633;
            }
            if (index < 40) {
                if (index < 38) {
                    if (index == 36) return 0x92a756e67e2b9413;
                    /* if (index == 37) */ return 0x70e741ebfee96586;
                }
                if (index == 38) return 0x019d5ee2af82ec1c;
                /* if (index == 39) */ return 0x6f6f2ed772466352;
            }
            if (index < 44) {
                if (index < 42) {
                    if (index == 40) return 0x7cf416cfe7e14ca1;
                    /* if (index == 41) */ return 0x61df517b86a46439;
                }
                if (index == 42) return 0x85dc499b11d77b75;
                /* if (index == 43) */ return 0x4b959b48b9c10733;
            }
            if (index < 46) {
                if (index == 44) return 0xe8be3e5da8043e57;
                /* if (index == 45) */ return 0xf5c0bc1de6da8699;
            }
            if (index == 46) return 0x40b12cbf09ef74bf;
            /* if (index == 47) */ return 0xa637093ecb2ad631;
        }
        if (index < 72) {
            if (index < 60) {
                if (index < 52) {
                    if (index < 50) {
                        if (index == 48) return 0x475cd3205a3bdcde;
                        /* if (index == 49) */ return 0x18a42105c31b7e88;
                    }
                    if (index == 50) return 0x023e7414af663068;
                    /* if (index == 51) */ return 0x15147108121967d7;
                }
                if (index < 56) {
                    if (index < 54) {
                        if (index == 52) return 0xe4a3dff1d7d6fef9;
                        /* if (index == 53) */ return 0x01a8d1a588085737;
                    }
                    if (index == 54) return 0x11b4c74eda62beef;
                    /* if (index == 55) */ return 0xe587cc0d69a73346;
                }
                if (index < 58) {
                    if (index == 56) return 0x1ff7327017aa2a6e;
                    /* if (index == 57) */ return 0x594e29c42473d06b;
                }
                if (index == 58) return 0xf6f31db1899b12d5;
                /* if (index == 59) */ return 0xc02ac5e47312d3ca;
            }
            if (index < 64) {
                if (index < 62) {
                    if (index == 60) return 0xe70201e960cb78b8;
                    /* if (index == 61) */ return 0x6f90ff3b6a65f108;
                }
                if (index == 62) return 0x42747a7245e7fa84;
                /* if (index == 63) */ return 0xd1f507e43ab749b2;
            }
            if (index < 68) {
                if (index < 66) {
                    if (index == 64) return 0x1c86d265f15750cd;
                    /* if (index == 65) */ return 0x3996ce73dd832c1c;
                }
                if (index == 66) return 0x8e7fba02983224bd;
                /* if (index == 67) */ return 0xba0dec7103255dd4;
            }
            if (index < 70) {
                if (index == 68) return 0x9e9cbd781628fc5b;
                /* if (index == 69) */ return 0xdae8645996edd6a5;
            }
            if (index == 70) return 0xdebe0853b1a1d378;
            /* if (index == 71) */ return 0xa49229d24d014343;
        }
        if (index < 84) {
            if (index < 76) {
                if (index < 74) {
                    if (index == 72) return 0x7be5b9ffda905e1c;
                    /* if (index == 73) */ return 0xa3c95eaec244aa30;
                }
                if (index == 74) return 0x0230bca8f4df0544;
                /* if (index == 75) */ return 0x4135c2bebfe148c6;
            }
            if (index < 80) {
                if (index < 78) {
                    if (index == 76) return 0x166fc0cc438a3c72;
                    /* if (index == 77) */ return 0x3762b59a8ae83efa;
                }
                if (index == 78) return 0xe8928a4c89114750;
                /* if (index == 79) */ return 0x2a440b51a4945ee5;
            }
            if (index < 82) {
                if (index == 80) return 0x80cefd2b7d99ff83;
                /* if (index == 81) */ return 0xbb9879c6e61fd62a;
            }
            if (index == 82) return 0x6e7c8f1a84265034;
            /* if (index == 83) */ return 0x164bb2de1bbeddc8;
        }
        if (index < 88) {
            if (index < 86) {
                if (index == 84) return 0xf3c12fe54d5c653b;
                /* if (index == 85) */ return 0x40b9e922ed9771e2;
            }
            if (index == 86) return 0x551f5b0fbe7b1840;
            /* if (index == 87) */ return 0x25032aa7c4cb1811;
        }
        if (index < 92) {
            if (index < 90) {
                if (index == 88) return 0xaaed34074b164346;
                /* if (index == 89) */ return 0x8ffd96bbf9c9c81d;
            }
            if (index == 90) return 0x70fc91eb5937085c;
            /* if (index == 91) */ return 0x7f795e2a5f915440;
        }
        if (index < 94) {
            if (index == 92) return 0x4543d9df5476d3cb;
            /* if (index == 93) */ return 0xf172d73e004fc90d;
        }
        if (index == 94) return 0xdfd1c4febcc81238;
        /* if (index == 95) */ return 0xbc8dfb627fe558fc;
        // revert("illegal index");
    }

    // `state[i]` allows 200 bits number.
    // `newState[i]` is 64 bits number.
    function _constantLayer(
        uint256[WIDTH] memory state,
        uint256 roundCtr
    ) internal pure returns (uint256[WIDTH] memory newState) {
        unchecked {
            // for (uint256 i = 0; i < 12; i++) {
            //     newState[i] = add(state[i], ALL_ROUND_CONSTANTS[i + WIDTH * roundCtr]);
            // }
            uint256 base_index = WIDTH * roundCtr;
            newState[0] = mod(state[0] + _getRoundConstant(base_index));
            newState[1] = mod(state[1] + _getRoundConstant(base_index + 1));
            newState[2] = mod(state[2] + _getRoundConstant(base_index + 2));
            newState[3] = mod(state[3] + _getRoundConstant(base_index + 3));
            newState[4] = mod(state[4] + _getRoundConstant(base_index + 4));
            newState[5] = mod(state[5] + _getRoundConstant(base_index + 5));
            newState[6] = mod(state[6] + _getRoundConstant(base_index + 6));
            newState[7] = mod(state[7] + _getRoundConstant(base_index + 7));
            newState[8] = mod(state[8] + _getRoundConstant(base_index + 8));
            newState[9] = mod(state[9] + _getRoundConstant(base_index + 9));
            newState[10] = mod(state[10] + _getRoundConstant(base_index + 10));
            newState[11] = mod(state[11] + _getRoundConstant(base_index + 11));
        }
    }

    // `x` allows 64 bits number.
    // `x7` is 192 bits number.
    function _sboxMonomial(uint256 x) internal pure returns (uint256 x7) {
        unchecked {
            uint256 x3 = x * x * x; // 192 bits
            x3 = mod(x3); // 64 bits
            x7 = x3 * x3 * x; // 192 bits
        }
    }

    function _mdsSboxLayer(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256[WIDTH] memory newState) {
        // _sbox_layer
        // for (uint256 i = 0; i < 12; i++) {
        //     state[i] = _sboxMonomial(state[i]);
        // }
        state[0] = _sboxMonomial(state[0]);
        state[1] = _sboxMonomial(state[1]);
        state[2] = _sboxMonomial(state[2]);
        state[3] = _sboxMonomial(state[3]);
        state[4] = _sboxMonomial(state[4]);
        state[5] = _sboxMonomial(state[5]);
        state[6] = _sboxMonomial(state[6]);
        state[7] = _sboxMonomial(state[7]);
        state[8] = _sboxMonomial(state[8]);
        state[9] = _sboxMonomial(state[9]);
        state[10] = _sboxMonomial(state[10]);
        state[11] = _sboxMonomial(state[11]);

        // _mds_layer
        // for (uint256 r = 0; r < 12; r++) {
        //     newState[r] = _mds_row_shf(r, state);
        // }
        newState[0] = _mdsRowShf0(state);
        newState[1] = _mdsRowShf1(state);
        newState[2] = _mdsRowShf2(state);
        newState[3] = _mdsRowShf3(state);
        newState[4] = _mdsRowShf4(state);
        newState[5] = _mdsRowShf5(state);
        newState[6] = _mdsRowShf6(state);
        newState[7] = _mdsRowShf7(state);
        newState[8] = _mdsRowShf8(state);
        newState[9] = _mdsRowShf9(state);
        newState[10] = _mdsRowShf10(state);
        newState[11] = _mdsRowShf11(state);
    }

    function _permute(
        uint256[WIDTH] memory state
    ) internal pure returns (uint256[WIDTH] memory) {
        // first full rounds
        state = _mdsSboxLayer(_constantLayer(state, 0));
        state = _mdsSboxLayer(_constantLayer(state, 1));
        state = _mdsSboxLayer(_constantLayer(state, 2));
        state = _mdsSboxLayer(_constantLayer(state, 3));

        // partial rounds
        state = _partialFirstLayer(state);

        // for (uint256 r = 0; r < 22; r++) {
        //     state[0] = _sboxMonomial(state[0]) + FAST_PARTIAL_ROUND_CONSTANTS[r];
        //     state = _mdsPartialLayerFast(state, r);
        // }
        unchecked {
            state[0] = _sboxMonomial(state[0]) + 0x74cb2e819ae421ab;
            state = _mdsPartialLayerFast(state, 0);
            state[0] = _sboxMonomial(state[0]) + 0xd2559d2370e7f663;
            state = _mdsPartialLayerFast(state, 1);
            state[0] = _sboxMonomial(state[0]) + 0x62bf78acf843d17c;
            state = _mdsPartialLayerFast(state, 2);
            state[0] = _sboxMonomial(state[0]) + 0xd5ab7b67e14d1fb4;
            state = _mdsPartialLayerFast(state, 3);
            state[0] = _sboxMonomial(state[0]) + 0xb9fe2ae6e0969bdc;
            state = _mdsPartialLayerFast(state, 4);
            state[0] = _sboxMonomial(state[0]) + 0xe33fdf79f92a10e8;
            state = _mdsPartialLayerFast(state, 5);
            state[0] = _sboxMonomial(state[0]) + 0x0ea2bb4c2b25989b;
            state = _mdsPartialLayerFast(state, 6);
            state[0] = _sboxMonomial(state[0]) + 0xca9121fbf9d38f06;
            state = _mdsPartialLayerFast(state, 7);
            state[0] = _sboxMonomial(state[0]) + 0xbdd9b0aa81f58fa4;
            state = _mdsPartialLayerFast(state, 8);
            state[0] = _sboxMonomial(state[0]) + 0x83079fa4ecf20d7e;
            state = _mdsPartialLayerFast(state, 9);
            state[0] = _sboxMonomial(state[0]) + 0x650b838edfcc4ad3;
            state = _mdsPartialLayerFast(state, 10);
            state[0] = _sboxMonomial(state[0]) + 0x77180c88583c76ac;
            state = _mdsPartialLayerFast(state, 11);
            state[0] = _sboxMonomial(state[0]) + 0xaf8c20753143a180;
            state = _mdsPartialLayerFast(state, 12);
            state[0] = _sboxMonomial(state[0]) + 0xb8ccfe9989a39175;
            state = _mdsPartialLayerFast(state, 13);
            state[0] = _sboxMonomial(state[0]) + 0x954a1729f60cc9c5;
            state = _mdsPartialLayerFast(state, 14);
            state[0] = _sboxMonomial(state[0]) + 0xdeb5b550c4dca53b;
            state = _mdsPartialLayerFast(state, 15);
            state[0] = _sboxMonomial(state[0]) + 0xf01bb0b00f77011e;
            state = _mdsPartialLayerFast(state, 16);
            state[0] = _sboxMonomial(state[0]) + 0xa1ebb404b676afd9;
            state = _mdsPartialLayerFast(state, 17);
            state[0] = _sboxMonomial(state[0]) + 0x860b6e1597a0173e;
            state = _mdsPartialLayerFast(state, 18);
            state[0] = _sboxMonomial(state[0]) + 0x308bb65a036acbce;
            state = _mdsPartialLayerFast(state, 19);
            state[0] = _sboxMonomial(state[0]) + 0x1aca78f31c97c876;
            state = _mdsPartialLayerFast(state, 20);
            state[0] = _sboxMonomial(state[0]) + 0x0000000000000000;
            state = _mdsPartialLayerFast(state, 21);
        }

        // second full rounds
        state = _mdsSboxLayer(_constantLayer(state, 4));
        state = _mdsSboxLayer(_constantLayer(state, 5));
        state = _mdsSboxLayer(_constantLayer(state, 6));
        state = _mdsSboxLayer(_constantLayer(state, 7));

        return state;
    }

    function permute(
        uint256[WIDTH] memory state
    ) external pure returns (uint256[WIDTH] memory newState) {
        state = _permute(state);
        for (uint256 i = 0; i < WIDTH; i++) {
            newState[i] = mod(state[i]);
        }
    }

    // Require each input[i] is less than 2^256 - 2^64.
    function _hashNToMNoPad(
        uint256[] memory input,
        uint256 numOutputs
    ) internal pure returns (uint256[] memory output) {
        uint256 numFullRound = input.length / SPONGE_RATE;
        uint256 lastRound = input.length % SPONGE_RATE;

        uint256[WIDTH] memory state;
        for (uint256 i = 0; i < numFullRound; i++) {
            // for (uint256 j = 0; j < SPONGE_RATE; j++) {
            //     state[j] = input[i * SPONGE_RATE + j];
            // }
            state[0] = input[i * SPONGE_RATE + 0];
            state[1] = input[i * SPONGE_RATE + 1];
            state[2] = input[i * SPONGE_RATE + 2];
            state[3] = input[i * SPONGE_RATE + 3];
            state[4] = input[i * SPONGE_RATE + 4];
            state[5] = input[i * SPONGE_RATE + 5];
            state[6] = input[i * SPONGE_RATE + 6];
            state[7] = input[i * SPONGE_RATE + 7];
            state = _permute(state);
        }
        for (uint256 j = 0; j < lastRound; j++) {
            state[j] = input[numFullRound * SPONGE_RATE + j];
        }
        state = _permute(state);

        output = new uint256[](numOutputs);
        for (uint256 j = 0; j < numOutputs; j++) {
            output[j] = mod(state[j]);
        }
    }

    function hashNToMNoPad(
        uint256[] memory input,
        uint256 numOutputs
    ) external pure returns (uint256[] memory output) {
        for (uint256 i = 0; i < input.length; i++) {
            input[i] = mod(input[i]);
        }
        output = _hashNToMNoPad(input, numOutputs);
    }

    function decodeHashOut(
        bytes32 encoded
    ) public pure returns (uint256[4] memory output) {
        uint256 value = abi.decode(abi.encode(encoded), (uint256));
        output[0] = value % (1 << 64);
        value >>= 64;
        output[1] = value % (1 << 64);
        value >>= 64;
        output[2] = value % (1 << 64);
        value >>= 64;
        output[3] = value;
    }

    function encodeHashOut(
        uint256[4] memory value
    ) public pure returns (bytes32 encoded) {
        encoded = abi.decode(
            abi.encodePacked(
                uint64(value[3]),
                uint64(value[2]),
                uint64(value[1]),
                uint64(value[0])
            ),
            (bytes32)
        );
    }

    function twoToOne(
        bytes32 left,
        bytes32 right
    ) public pure returns (bytes32 output) {
        uint256[4] memory hashLeft = decodeHashOut(left);
        uint256[4] memory hashRight = decodeHashOut(right);
        uint256[12] memory state;
        state[0] = hashLeft[0];
        state[1] = hashLeft[1];
        state[2] = hashLeft[2];
        state[3] = hashLeft[3];
        state[4] = hashRight[0];
        state[5] = hashRight[1];
        state[6] = hashRight[2];
        state[7] = hashRight[3];
        state = _permute(state);
        uint256[4] memory hashOut;
        hashOut[0] = mod(state[0]);
        hashOut[1] = mod(state[1]);
        hashOut[2] = mod(state[2]);
        hashOut[3] = mod(state[3]);
        output = encodeHashOut(hashOut);
    }
}
