# IntMax interoperability plugin

## Concept

See [Concept](./docs/concept.md)

## How to deploy OfferManager

Setup a local node.

```sh
git submodule init
git submodule update
cd contracts
npx hardhat node # port 8545
cd ../
```

Deploy OfferManager contract.

```sh
cp -n example.env .env
cargo install cargo-make
RPC_URL=http://localhost:8545 cargo make deploy-contracts
```


## How to test on Scroll alpha

Access to OfferManager contract deployed on Scroll.
The account given in .env file must have sufficient ETH (around 0.1 ETH) on Scroll alpha to execute the transaction.

```sh
cargo run --bin offer_manager
```

## How to develop Solidity

See also [sample-auction-app](https://github.com/InternetMaximalism/intmax-rollup-cli-flag/tree/main/packages/sample-auction-app/ethereum).

### Offer Manager (Pattern 1)

1. Mike burns the intmax token A.
2. Mike registers a new offer and declares that he will transfer his burned assets to the account that has transferred ETH to him.
3. Tom accepts the offer and transfers the ETH to Mike.
4. Tom can merge the assets transferred from Mike on intmax.

#### [register()](./contracts/contracts/OfferManagerInterface.sol#L42-L60)

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

#### [activate()](./contracts/contracts/OfferManagerInterface.sol#L69-L73)

```solidity
OfferManagerInterface offerManager;
bool success = offerManager.activate{
    value: takerAmount
}(offerId);
require(success, "fail to activate offer");
```

### Offer Manager (Pattern 2)

1. Tom locks his ETH and registers the offer. This declares that he will transfer the locked assets to the account that has transferred the specified token on intmax to him.
2. Mike accepts the offer and transfers the tokens on intmax to Tom.
3. Mike can receive Tom's ETH.

#### [register()](./contracts/contracts/OfferManagerReverseInterface.sol#L39-L53)

```solidity
OfferManagerReverseInterface offerManagerReverse;
uint256 offerId = offerManagerReverse.register(
    takerIntmax,
    maker,
    makerAssetId,
    makerAmount
);
```

#### [activate()](./contracts/contracts/OfferManagerReverseInterface.sol#L62-L70)

```solidity
OfferManagerReverseInterface offerManagerReverse;
bool success = offerManagerReverse.activate(
    offerId,
    witness
);
require(success, "fail to unlock offer");
```
