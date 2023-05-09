// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice This contract is the ERC20 token for testing.
 * When the contract is deployed, it mints 10^18 tokens to the deployer.
 */
contract ERC20Test is ERC20 {
    constructor() ERC20("ERC20Test", "TEST") {
        ERC20._mint(_msgSender(), 1e18);
    }
}
