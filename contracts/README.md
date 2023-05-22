# Offer Manager Contracts for INTMAX Interoperability

## How to Test

```sh
git submodule update --init
npx hardhat test
REPORT_GAS=true npx hardhat test # if you need to update the gas report
forge compile --sizes
forge test -vv
```

## Deploy Locally

```sh
npx hardhat node
npx hardhat run scripts/deploy.ts --network localhost
```
