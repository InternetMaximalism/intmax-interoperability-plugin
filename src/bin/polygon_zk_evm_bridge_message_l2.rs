use std::{sync::Arc, time::Duration};

use dotenv::dotenv;
use ethers::{
    core::types::Address,
    middleware::SignerMiddleware,
    prelude::k256::ecdsa::SigningKey,
    providers::{Http, Provider},
    signers::LocalWallet,
    utils::secret_key_to_address,
};
use intmax_interoperability_plugin::{
    contracts::polygon_zk_evm_bridge::PolygonZkEVMBridgeContractWrapper,
    zk_evm_exit_tree::ResponsePolygonExitMerkleProof,
};

#[tokio::main]
async fn main() {
    let _ = dotenv().ok();
    let secret_key = std::env::var("PRIVATE_KEY").expect("PRIVATE_KEY must be set in .env file");
    let rpc_url = "https://rpc.public.zkevm-test.net";
    let chain_id = 1442u64;

    let provider = Provider::<Http>::try_from(rpc_url)
        .unwrap()
        .interval(Duration::from_millis(10u64));
    let signer_key = SigningKey::from_bytes(&hex::decode(&secret_key).unwrap()).unwrap();
    let my_account = secret_key_to_address(&signer_key);
    let wallet = LocalWallet::new_with_signer(signer_key, my_account, chain_id);
    let client = SignerMiddleware::new(provider, wallet);
    let client = Arc::new(client);

    let contract_address: Address = "0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7"
        .parse()
        .unwrap();
    let contract = PolygonZkEVMBridgeContractWrapper::new(contract_address, client);

    // Fetch by polygon_zk_evm_bridge_message_l1.rs .
    let metadata = "0x22334455667788".parse().unwrap();
    let deposit_count = 37980u32;

    let network_id = 1u32;
    let body = reqwest::get(format!(
        "https://bridge-api.public.zkevm-test.net/merkle-proof?request=net_id={}&deposit_cnt={}",
        network_id, deposit_count
    ))
    .await
    .unwrap()
    .text()
    .await
    .unwrap();

    let exit_merkle_proof: ResponsePolygonExitMerkleProof = serde_json::from_str(&body).unwrap();

    println!("start claim_message()");
    {
        // get `smt_proof` from https://bridge-api.public.zkevm-test.net/merkle-proof
        let smt_proof = exit_merkle_proof.proof.merkle_proof;
        let index = deposit_count;
        let mainnet_exit_root = exit_merkle_proof.proof.main_exit_root;
        let rollup_exit_root = exit_merkle_proof.proof.rollup_exit_root;
        let origin_network = 0;
        let origin_address = my_account;
        let destination_network = 1;
        let destination_address = my_account;
        let amount = 0u128.into();
        contract
            .claim_message(
                smt_proof,
                index,
                mainnet_exit_root,
                rollup_exit_root,
                origin_network,
                origin_address,
                destination_network,
                destination_address,
                amount,
                metadata,
            )
            .send()
            .await
            .unwrap();
    }
    println!("end claim_message()");
}
