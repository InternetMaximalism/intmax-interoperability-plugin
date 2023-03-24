# IntMax interoperability plugin

## Concept

See [Concept](./docs/concept.md)

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

See also [sample-auction-app](https://github.com/InternetMaximalism/intmax-rollup-cli-flag/tree/main/packages/sample-auction-app/contract).

### [register()](./contracts/contracts/OfferManagerInterface.sol#L42-L60)

```solidity
OfferManagerInterface offerManager;
uint256 offerId = offerManager.register(
    makerIntmax,
    makerAssetId,
    makerAmount,
    taker,
    takerIntmax,
    takerTokenAddress,
    takerAmount
);
```

### [activate()](./contracts/contracts/OfferManagerInterface.sol#L69-L73)

```solidity
OfferManagerInterface offerManager;
bool success = offerManager.activate{
    value: takerAmount
}(offerId);
require(success, "fail to activate offer");
```

### [lock()](./contracts/contracts/OfferManagerReverseInterface.sol#L39-L53)

```solidity
OfferManagerReverseInterface offerManagerReverse;
uint256 offerId = offerManagerReverse.lock(
    makerIntmax,
    taker,
    takerIntmax,
    takerAssetId,
    takerAmount
);
```

### [unlock()](./contracts/contracts/OfferManagerReverseInterface.sol#L62-L70)

```solidity
OfferManagerReverseInterface offerManagerReverse;
bool success = offerManagerReverse.unlock(
    offerId,
    witness
);
require(success, "fail to unlock offer");
```
