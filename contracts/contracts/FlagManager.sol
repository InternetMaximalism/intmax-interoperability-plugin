// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract FlagManager {
    struct Remittance {
        address recipient;
        uint256 assetId;
        uint256 amount;
    }

    uint256 constant MAX_ASSET_ID = 18446744069414584320; // the maximum value of Goldilocks field
    uint256 constant MAX_REMITTANCE_AMOUNT = 18446744069414584320; // the maximum value of Goldilocks field

    /**
     * @dev This is the ID allocated to the next remittance data to be registered.
     */
    uint256 public nextFlagId = 0;

    /**
     * @dev This is the mapping that indicates whether the flag ID has been activated.
     */
    mapping(uint256 => bool) flags;

    /**
     * @dev This is the mapping from flag ID to its owner.
     */
    mapping(uint256 => address) owners;

    /**
     * @dev This is the mapping from flag ID to remittance data.
     */
    mapping(uint256 => Remittance) remittances;

    /**
     * This event occurs when certain flags are registered.
     * @param flagId is the ID of the flag.
     * @param recipient is the account.
     * @param assetId is the asset ID.
     * @param amount is the amount.
     */
    event Register(
        uint256 indexed flagId,
        address indexed recipient,
        uint256 indexed assetId,
        uint256 amount
    );

    /**
     * This event occurs when certain flags are activated.
     * @param flagId is the ID of the flag.
     */
    event Activate(uint256 indexed flagId);

    /**
     * This function registers a new flag.
     * @param recipient is the account you want to transfer.
     * @param assetId is the asset ID you want to transfer.
     * @param amount is the amount you want to transfer.
     */
    function _register(
        address recipient,
        uint256 assetId,
        uint256 amount
    ) internal returns (uint256 flagId) {
        // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
        // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

        require(
            msg.sender != address(0),
            "The owner must not be zero address."
        );
        flagId = nextFlagId;
        require(!isRegistered(flagId), "This flag ID is already registered.");
        owners[flagId] = msg.sender;

        Remittance memory remittance = Remittance({
            recipient: recipient,
            assetId: assetId,
            amount: amount
        });
        _isValidRemittance(remittance);
        remittances[flagId] = remittance;
        nextFlagId += 1;
        emit Register(flagId, recipient, assetId, amount);
    }

    function isRegistered(uint256 flagId) public view returns (bool) {
        return (owners[flagId] != address(0));
    }

    function isActivated(uint256 flagId) public view returns (bool) {
        return flags[flagId];
    }

    /**
     * This function activates a flag.
     * @param flagId is the ID of the flag.
     */
    function _activate(uint256 flagId) internal {
        require(isRegistered(flagId), "This flag ID has not been registered.");
        require(!isActivated(flagId), "This flag ID is already activated.");
        flags[flagId] = true;
        emit Activate(flagId);
    }

    function _isValidRemittance(Remittance memory remittance) internal pure {
        require(remittance.assetId <= MAX_ASSET_ID, "invalid asset ID");
        require(
            remittance.amount <= MAX_REMITTANCE_AMOUNT,
            "invalid remittance amount"
        );
    }
}
