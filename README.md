# IntMax interoperability plugin

## Concept

It is a smart contract written in Solidity to manage offers to exchange assets on INTMAX and other networks.
The contract allows users to register new offers and update the taker of an existing offer. The offer can be activated by transferring the taker's asset to the maker in exchange for payment. The contract also includes events for tracking the registration, activation, and deactivation of offers. The function nextOfferId returns the ID of the next offer to be registered.

See also [Concept](./docs/concept.md).

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

There are two characters in [Concept](./docs/concept.md) - Mike (maker) and Tom (taker).
These names are also used in the following description.

### Network Index

The network index is the following:
- Scroll Alpha: 0x0000000000000000000000000000000000000000000000000000000000000001
- Polygon ZKEVM Test: 0x0000000000000000000000000000000000000000000000000000000000000002

### Transaction Witness

You can calculate the witness that you sent the transaction:

```sh
intmax account transaction-proof <tx-hash> <tom-intmax-address>
```

### Offer Manager (Pattern 1)

1. Mike sends the token A to the address `networkIndex` on INTMAX.
2. Mike calculates witness that he sent the transaction.
3. Mike registers a new offer and declares that he will transfer his burned assets to the account that has transferred ETH to him.
4. Tom accepts the offer and transfers the ETH to Mike.
5. Tom can merge the assets transferred from Mike on INTMAX.

#### [register()](./contracts/contracts/OfferManagerInterface.sol#L75)

This function registers a new offer.
It requires:
- `takerTokenAddress` must be a valid address.
- `takerIntmax` must not be zero.
- The caller must not be a zero address.
- The offer ID must not be already registered.
- The offer must be valid.
- Given witness is valid.

```solidity
OfferManagerInterface offerManager;
uint256 offerId = offerManager.register(
    makerIntmax,
    makerAssetId,
    makerAmount,
    taker,
    takerIntmax,
    takerTokenAddress,
    takerAmount,
    witness
);
```

#### [activate()](./contracts/contracts/OfferManagerInterface.sol#L113)

This function activates an offer by transferring the taker's asset to the maker in exchange for payment.
`offerId` is the ID of the offer to activate.
It Returns a boolean indicating whether the offer is successfully activated.
This function requires:
- The offer must exist.
- The offer must not be already activated.
- Only the taker can activate it.
- The payment must be equal to or greater than the taker's asset amount.

```solidity
OfferManagerInterface offerManager;
bool success = offerManager.activate{
    value: takerAmount
}(offerId);
require(success, "fail to activate offer");
```

### Offer Manager (Pattern 2)

1. Tom locks his ETH and registers the offer. This declares that he will transfer the locked assets to the account that has transferred the specified token on INTMAX to him.
2. Mike transfers the tokens on INTMAX to Tom.
3. Mike calculates witness that he sent the transaction.
4. Mike accepts the offer.
5. Mike can receive Tom's ETH.

#### [register()](./contracts/contracts/OfferManagerReverseInterface.sol#L41)

Locks the taker's funds and creates a new offer to exchange them for the maker's asset on INTMAX.
ATTENTION: This offer cannot be cancelled.
This function requires:
- The taker must not be the zero address.
- The offer ID must not be already registered.
- The maker's offer amount must be less than or equal to MAX_REMITTANCE_AMOUNT.

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

#### [activate()](./contracts/contracts/OfferManagerReverseInterface.sol#L93)

This function accepts an offer and transfers the taker's asset to the maker.
This function requires:
- The offer must exist.
- The offer must not be already activated.
- Only the maker can activate the offer.
- Given witness is valid.

```solidity
OfferManagerReverseInterface offerManagerReverse;
bool success = offerManagerReverse.activate(
    offerId,
    witness
);
require(success, "fail to unlock offer");
```

### Examples

See [sample-auction-app](https://github.com/InternetMaximalism/intmax-rollup-cli/tree/main/packages/sample-auction-app/ethereum).
