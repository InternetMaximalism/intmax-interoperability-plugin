use serde::Deserialize;
use web3::{
    contract::{Contract, Options},
    types::{H160, U256},
};

extern crate tokio;

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct HardHatSolidityArtifacts {
    #[serde(rename = "contractName")]
    pub contract_name: String,
    pub abi: web3::ethabi::Contract,
    pub bytecode: String,
    #[serde(rename = "deployedBytecode")]
    pub deployed_bytecode: String,
}

#[tokio::main]
async fn main() -> web3::contract::Result<()> {
    let transport = web3::transports::Http::new("http://localhost:8545")?;
    let web3 = web3::Web3::new(transport);

    // let accounts = web3.eth().accounts().await?;
    // dbg!(&accounts);

    let artifacts: HardHatSolidityArtifacts = serde_json::from_str(include_str!(
        "../contracts/artifacts/contracts/FlagManager.sol/FlagManager.json"
    ))
    .unwrap();

    // // Deploying a contract
    // let deployer_account = accounts[0];
    // let contract = Contract::deploy(web3.eth(), artifacts.abi)?
    //     .confirmations(0)
    //     .options(Options::with(|_opt| {
    //         // _opt.value = Some(5u32.into());
    //         // _opt.gas_price = Some(1_000_000_000u32.into());
    //         // _opt.gas = Some(30_000_000u32.into());
    //     }))
    //     .execute(artifacts.bytecode, (), deployer_account)
    //     .await?;

    let contract_address: H160 = "5FbDB2315678afecb367f032d93F642f64180aa3".parse().unwrap();
    let contract = Contract::new(web3.eth(), contract_address, artifacts.abi);
    let next_flag_id: U256 = contract
        .query("nextFlagId", (), None, Options::default(), None)
        .await?;
    assert_eq!(next_flag_id, 0u32.into());

    Ok(())
}
