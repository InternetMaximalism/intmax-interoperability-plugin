# IntMax interoperability plugin

## Concept

If Bob sends a token to Alice on another L2 with zkEVM, a function whereby Alice sends a token to Bob on intmax.
The network with zkEVM functionality is called network 1.
Alice first burns the tokens she wants to send to Bob on intmax. Alice then records the amount of money she wants to receive from Bob on network 1 via the register() function.
Bob confirms that Alice has correctly burnt the token on intmax and then sends the token that Alice wants through the activate() function. The intmax network then reflects this information and Bob can receive the tokens Alice has incinerated on intmax.

## How to test

Setup a local node.

```sh
git submodule init
git submodule update
cd packages/intmax-interoperability-plugin/contracts
npx hardhat node # port 8545
```

Deploy FlagManager contract.

```sh
cd packages/intmax-interoperability-plugin
cp -n example.env .env
cargo install cargo-make
cargo make deploy-contracts
```

Interact to the contract.

```sh
cargo run --bin offer_manager
```

## How to develop Solidity

See also sample-auction-app

### register()

```solidity
/**
  * This function registers a new offer.
  * @param makerIntmax is the maker's intmax account.
  * @param makerAssetId is the asset ID a maker sell to taker.
  * @param makerAmount is the amount a maker sell to taker.
  * @param taker is the taker's account.
  * @param takerIntmax is the taker's intmax account.
  * @param takerTokenAddress is the token address a taker should pay.
  * @param takerAmount is the amount a taker should pay.
  */
function register(
    bytes32 makerIntmax,
    uint256 makerAssetId,
    uint256 makerAmount,
    address taker,
    bytes32 takerIntmax,
    address takerTokenAddress,
    uint256 takerAmount
) external returns (uint256 flagId);
```

### activate()

```solidity
/**
  * This function activate a offer in exchange for payment.
  * @param offerId is the ID of the offer.
  */
function activate(uint256 offerId) external payable returns (bool);
```
