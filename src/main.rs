use std::str::FromStr;

use dotenv::dotenv;
use secp256k1::key::SecretKey;
use web3::{
    signing::{Key, SecretKeyRef},
    types::{H160, U256},
};

use intmax_interoperability_plugin::*;

#[tokio::main]
async fn main() {
    let _ = dotenv().ok();
    let secret_key = SecretKey::from_str(
        &std::env::var("PRIVATE_KEY").expect("PRIVATE_KEY must be set in .env file."),
    )
    .unwrap();
    let rpc_url = std::env::var("RPC_URL").expect("RPC_URL must be set in .env file.");

    let transport = web3::transports::Http::new(&rpc_url).unwrap();
    let web3 = web3::Web3::new(transport);

    // let accounts = web3.eth().accounts().await.unwrap();
    // dbg!(&accounts);

    let my_account = SecretKeyRef::new(&secret_key).address();

    // // Deploying a contract
    // let deployer_account = accounts[0];
    // let contract = Contract::deploy(web3.eth(), artifacts.abi)?
    //     .confirmations(0)
    //     .options(Options::with(|_opt| {
    //         // _opt.value = Some(5u32.into());x
    //         // _opt.gas_price = Some(1_000_000_000u32.into());
    //         // _opt.gas = Some(30_000_000u32.into());
    //     }))
    //     .execute(artifacts.bytecode, (), deployer_account)
    //     .await?;

    let contract_address: H160 = std::env::var("CONTRACT_ADDRESS")
        .expect("CONTRACT_ADDRESS must be set in .env file.")
        .parse()
        .unwrap();
    let contract = FlagManagerContract::new(&web3, contract_address);
    let next_flag_id: U256 = contract.next_flag_id().await.unwrap();
    // assert_eq!(next_flag_id, 1u32.into());

    println!("start register()");
    let _res = contract
        .register(
            SecretKeyRef::new(&secret_key),
            my_account,
            1u8.into(),
            100u64.into(),
        )
        .await
        .unwrap();
    println!("end register()");

    let next_next_flag_id: U256 = contract.next_flag_id().await.unwrap();
    assert_eq!(next_next_flag_id, next_flag_id + U256::from(1u8));

    let is_registered = contract.is_registered(next_flag_id).await.unwrap();
    assert!(is_registered);

    let logs = contract.get_register_events().await.unwrap();
    dbg!(logs);

    println!("start activate()");
    let _res = contract
        .activate(SecretKeyRef::new(&secret_key), next_flag_id)
        .await
        .unwrap();
    println!("end activate()");

    let logs = contract.get_activate_events().await.unwrap();
    dbg!(logs);

    let is_activated = contract.is_activated(next_flag_id).await.unwrap();
    assert!(is_activated);
}
