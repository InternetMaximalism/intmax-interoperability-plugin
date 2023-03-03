use std::{sync::Arc, time::Duration};

use dotenv::dotenv;
use ethers::{
    core::types::{Address, U256},
    middleware::SignerMiddleware,
    prelude::k256::ecdsa::SigningKey,
    providers::{Http, Provider},
    signers::LocalWallet,
    utils::secret_key_to_address,
};
use intmax_interoperability_plugin::FlagManagerContractWrapper;

#[tokio::main]
async fn main() {
    let _ = dotenv().ok();
    let secret_key = std::env::var("PRIVATE_KEY").expect("PRIVATE_KEY must be set in .env file");
    let rpc_url = std::env::var("RPC_URL").expect("RPC_URL must be set in .env file");
    let chain_id: u64 = std::env::var("CHAIN_ID")
        .expect("CHAIN_ID must be set in .env file")
        .parse()
        .unwrap();

    let provider = Provider::<Http>::try_from(&rpc_url)
        .unwrap()
        .interval(Duration::from_millis(10u64));
    let signer_key = SigningKey::from_bytes(&hex::decode(&secret_key).unwrap()).unwrap();
    let my_account = secret_key_to_address(&signer_key);
    let wallet = LocalWallet::new_with_signer(signer_key, my_account, chain_id);
    let client = SignerMiddleware::new(provider, wallet);
    let client = Arc::new(client);

    let contract_address: Address = std::env::var("CONTRACT_ADDRESS")
        .expect("CONTRACT_ADDRESS must be set in .env file")
        .parse()
        .unwrap();
    let contract = FlagManagerContractWrapper::new(contract_address, client);

    let next_flag_id: U256 = contract.next_flag_id().call().await.unwrap();
    dbg!(next_flag_id);

    println!("start register()");
    contract
        .register(my_account, 1u8.into(), 100u64.into())
        .send()
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
    contract.test_activate(next_flag_id).send().await.unwrap();
    println!("end activate()");

    let logs = contract.get_activate_events().await.unwrap();
    dbg!(logs);

    let is_activated = contract.is_activated(next_flag_id).await.unwrap();
    assert!(is_activated);
}
