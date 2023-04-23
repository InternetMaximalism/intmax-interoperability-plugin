import { HardhatUserConfig } from "hardhat/config";
import "hardhat-gas-reporter";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";

require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY!;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    scrollalpha: {
      url: `https://alpha-rpc.scroll.io/l2`,
      chainId: 534353,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    polygonzkevmtest: {
      url: `https://rpc.public.zkevm-test.net`,
      chainId: 1442,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    currency: "USD",
    gasPrice: 50,
    outputFile: "./reports/gas-report",
    noColors: true,
  },
};

export default config;
