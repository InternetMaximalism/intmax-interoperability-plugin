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
use intmax_interoperability_plugin::contracts::offer_manager::OfferManagerContractWrapper;

#[tokio::main]
async fn main() {
    let _ = dotenv().ok();
    let secret_key =
        std::env::var("PRIVATE_KEY").expect("PRIVATE_KEY must be set in .env file. This address must have sufficient ETH (around 0.1 ETH) on Scroll alpha to execute the transaction.");
    let rpc_url = "https://alpha-rpc.scroll.io/l2";
    let chain_id = 534353u64;

    let provider = Provider::<Http>::try_from(rpc_url)
        .unwrap()
        .interval(Duration::from_millis(10u64));
    let signer_key = SigningKey::from_bytes(&hex::decode(&secret_key).unwrap()).unwrap();
    let my_account = secret_key_to_address(&signer_key);
    let wallet = LocalWallet::new_with_signer(signer_key, my_account, chain_id);
    let client = SignerMiddleware::new(provider, wallet);
    let client = Arc::new(client);

    let contract_address: Address = "0x007c969728eE4f068ceCF3405D65a037dB5BeEa1"
        .parse()
        .unwrap();
    let contract = OfferManagerContractWrapper::new(contract_address, client);

    let next_offer_id: U256 = contract.next_offer_id().call().await.unwrap();
    dbg!(next_offer_id);

    // // TODO: Rewriting without using the test function.
    // println!("start register()");
    // contract
    //     .test_register(
    //         [0u8; 32],     // maker_intmax
    //         1u8.into(),    // maker_asset_id
    //         100u64.into(), // maker_amount
    //         my_account,    // taker
    //         [0u8; 32],     // taker_intmax
    //         "0x0000000000000000000000000000000000000000"
    //             .parse()
    //             .unwrap(), // taker_token_address
    //         1u8.into(),    // taker_amount
    //     )
    //     .send()
    //     .await
    //     .unwrap();
    // println!("end register()");

    // let next_next_offer_id: U256 = contract.next_offer_id().await.unwrap();
    // assert_eq!(next_next_offer_id, next_offer_id + U256::from(1u8));

    // let is_registered = contract.is_registered(next_offer_id).await.unwrap();
    // assert!(is_registered);

    // let logs = contract.get_register_events(vec![]).await.unwrap();
    // dbg!(logs);

    // println!("start activate()");
    // contract.test_activate(next_offer_id).send().await.unwrap();
    // println!("end activate()");

    // let logs = contract.get_activate_events().await.unwrap();
    // dbg!(logs);

    // let is_activated = contract.is_activated(next_offer_id).await.unwrap();
    // assert!(is_activated);
}
