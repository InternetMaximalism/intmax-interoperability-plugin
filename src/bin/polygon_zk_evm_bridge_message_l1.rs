use std::{sync::Arc, time::Duration};

use dotenv::dotenv;
use ethers::{
    core::types::Address,
    middleware::SignerMiddleware,
    prelude::k256::ecdsa::SigningKey,
    providers::{Http, Provider},
    signers::LocalWallet,
    types::TransactionReceipt,
    utils::secret_key_to_address,
};
use intmax_interoperability_plugin::contracts::polygon_zk_evm_bridge::PolygonZkEVMBridgeContractWrapper;

#[tokio::main]
async fn main() {
    let _ = dotenv().ok();
    let secret_key = std::env::var("PRIVATE_KEY").expect("PRIVATE_KEY must be set in .env file");
    let infura_project_id =
        std::env::var("INFURA_PROJECT_ID").expect("INFURA_PROJECT_ID must be set in .env file");
    let rpc_url = &format!("https://goerli.infura.io/v3/{}", infura_project_id);
    let chain_id = 5u64;

    let provider = Provider::<Http>::try_from(rpc_url)
        .unwrap()
        .interval(Duration::from_millis(10u64));
    let signer_key = SigningKey::from_bytes(&hex::decode(&secret_key).unwrap()).unwrap();
    let my_account = secret_key_to_address(&signer_key);
    let wallet = LocalWallet::new_with_signer(signer_key, my_account, chain_id);
    let client: SignerMiddleware<Provider<Http>, _> = SignerMiddleware::new(provider, wallet);
    let client = Arc::new(client);

    let contract_address: Address = "0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7"
        .parse()
        .unwrap();
    let contract = PolygonZkEVMBridgeContractWrapper::new(contract_address, client.clone());

    println!("start bridge_message()");
    let receipt: Option<TransactionReceipt> = {
        let destination_network = 1;
        let destination_address = my_account;
        let force_update_global_exit_root = true;
        let metadata = "0x22334455667788".parse().unwrap();

        contract
            .bridge_message(
                destination_network,
                destination_address,
                force_update_global_exit_root,
                metadata,
            )
            .send()
            .await
            .unwrap()
            .await
            .unwrap()
    };
    println!("end bridge_message()");

    let block_number = match receipt {
        Some(r) => r.block_number,
        _ => None,
    };

    let logs = contract
        .get_bridge_events(
            vec![my_account],
            block_number.unwrap(),
            block_number.unwrap(),
        )
        .await
        .unwrap();
    dbg!(logs);
}
