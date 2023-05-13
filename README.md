# INTMAX interoperability plugin

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

## How to develop Solidity

The address of the deployed contract can be found [here](./docs/address.json).

### Offer Manager (Pattern 1)

Two characters appear below - Mike and Tom.
Mike wants to receive tokens on Scroll from Tom instead of sending tokens on INTMAX to Tom.

#### 1. Mike sends the token to the address `networkIndex` on INTMAX

```sh
intmax tx send -a <token-intmax-address> --amount 1 -i 0x00 --receiver-address <network-name>
```

For example, if you want to make an offer on Scroll Alpha Testnet:

```sh
intmax tx send -a 0x98c1fd6f55e2ccee --amount 1 -i 0x00 --receiver-address scroll
```

Currently supported networks are "scroll" (Scroll Alpha Testnet) and "polygon" (Polygon ZKEVM Testnet).

You must have a sufficient balance yourself to run the above command. You can check your balance with the following command.

```sh
intmax account assets
```

#### 2. Mike calculates witness that he sent the transaction

```sh
intmax account transaction-proof <tx-hash> <network-name>
```

#### 3. Mike registers a new offer.

Call the `register()` function of `OfferManager` contract using the witness obtained earlier.
This declares that he will transfer his burned assets to the account that has transferred ETH to him.

```solidity
OfferManagerV2Interface offerManager;
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

It requires:

- `makerAmount` must be less than or equal to `MAX_REMITTANCE_AMOUNT` (about 64 bits).
- `takerTokenAddress` must be a valid address.
- `takerIntmax` must not be zero.
- The offer ID must not be already registered.
- The offer must be valid.
- Given witness is valid.

#### 4. Tom accepts the offer and transfers the ETH to Mike.

Call the `activate()` function of `OfferManager` contract.

```solidity
OfferManagerV2Interface offerManager;
bool success = offerManager.activate{
    value: takerAmount
}(offerId);
require(success, "fail to activate offer");
```

It requires:

- The offer must exist.
- The offer must not be already activated.
- Only the taker can activate it.
- The payment must be equal to or greater than the taker's asset amount.

#### 5. Tom can merge the assets transferred from Mike on INTMAX.

```sh
intmax tx merge
```

### Offer Manager (Pattern 2)

This time we will make an offer from Tom.
Tom wants to receive a token on INTMAX from Mike instead of sending a token on Scroll to Mike.

#### 1. Tom locks his ETH and registers the offer.

Call the `register()` function of `OfferManagerReverse` contract.
This declares that he will transfer the locked assets to the account that has transferred the specified token on INTMAX to him.

```solidity
OfferManagerReverseV2Interface offerManagerReverse;
uint256 offerId = offerManagerReverse.register(
    takerIntmaxAddress,
    takerTokenAddress,
    takerAmount,
    maker,
    makerAssetId,
    makerAmount
);
```

It requires:

- The offer ID must not be already registered.
- `makerAmount` must be less than or equal to `MAX_REMITTANCE_AMOUNT` (about 64 bits).

ATTENTION: This offer cannot be cancelled.

#### 2. Mike transfers the tokens on INTMAX to Tom

```sh
intmax tx send --amount 1 -i 0x00 --receiver-address <tom-intmax-address>
```

#### 3. Mike calculates witness that he sent the transaction

```sh
intmax account transaction-proof <tx-hash> <tom-intmax-address>
```

The output of this command is "witness".

#### 4. Mike activates the offer

Call the `activate()` function of `OfferManagerReverse` contract using the witness obtained earlier.
After that, Mike received Tom's ETH.

```solidity
OfferManagerReverseV2Interface offerManagerReverse;
bool success = offerManagerReverse.activate(
    offerId,
    witness
);
require(success, "fail to unlock offer");
```

It requires:

- The offer must exist.
- The offer must not be already activated.
- Only the maker can activate the offer.
- Given witness is valid.

### Examples

See [sample-auction-app](https://github.com/InternetMaximalism/intmax-rollup-cli/tree/main/packages/sample-auction-app/ethereum).
