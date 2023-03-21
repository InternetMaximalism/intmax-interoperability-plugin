# IntMax interoperability plugin

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
