# IntMax interoperability plugin

## Concept

It is a smart contract written in Solidity to manage offers to exchange assets on intmax and other networks.
The contract allows users to register new offers and update the taker of an existing offer. The offer can be activated by transferring the taker's asset to the maker in exchange for payment. The contract also includes events for tracking the registration, activation, and deactivation of offers. The function nextOfferId returns the ID of the next offer to be registered.

See also [Concept](./docs/concept.md)

## How to deploy OfferManager on local network

Clone this repository.

```sh
# use SSH
git clone git@github.com:InternetMaximalism/intmax-interoperability-plugin.git
# or use HTTPS
git clone https://github.com/InternetMaximalism/intmax-interoperability-plugin.git
cd ​​intmax-interoperability-plugin
```

Setup a local node.

```sh
git submodule init
git submodule update
cd contracts
npx hardhat node # port 8545
```

Open another terminal and return to this repository root.
Next, setup environment variables.

```sh
cp -n example.env .env
```

In the .env file, `PRIVATE_KEY` is required to deploy the contract.
The code below deploys the contract to the network specified by `RPC_URL`,
so the account must have sufficient ETH in advance.
If you use Hardhat node at `http://localhost:8545`,
the private key in `example.env` may be used without modification.

```sh
cd contracts
npx hardhat --network localhost run ./scripts/deploy.ts
```

## How to test on Scroll alpha

By executing the following command, you can access to OfferManager contract deployed on Scroll.
The account given in .env file must have sufficient ETH (around 0.1 ETH) on Scroll alpha to execute the transaction.

```sh
cargo run --bin offer_manager
```

The address of the deployed contract can be found [here](./docs/address.json).

## How to develop Solidity

See also [sample-auction-app](https://github.com/InternetMaximalism/intmax-rollup-cli/tree/main/packages/sample-auction-app/ethereum).

### Offer Manager (Pattern 1)

1. Mike burns the intmax token A.
2. Mike registers a new offer and declares that he will transfer his burned assets to the account that has transferred ETH to him.
3. Tom accepts the offer and transfers the ETH to Mike.
4. Tom can merge the assets transferred from Mike on intmax.

#### [register()](./contracts/contracts/OfferManagerInterface.sol#L53-L79)

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

#### [activate()](./contracts/contracts/OfferManagerInterface.sol#L96-L107)

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

#### [register()](./contracts/contracts/OfferManagerReverseInterface.sol#L40-L56)

```solidity
OfferManagerReverseInterface offerManagerReverse;
uint256 offerId = offerManagerReverse.register(
    takerIntmaxAddress,
    takerTokenAddress,
    takerAmount,
    maker,
    makerAssetId,
    makerAmount
);
```

#### [activate()](./contracts/contracts/OfferManagerReverseInterface.sol#L69-L81)

```solidity
OfferManagerReverseInterface offerManagerReverse;
bool success = offerManagerReverse.activate(
    offerId,
    witness
);
require(success, "fail to unlock offer");
```
