use ethers::contract::abigen;

abigen!(
    Erc20Interface,
    "./contracts/compiled-artifacts/@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol/IERC20Metadata.json"
);
