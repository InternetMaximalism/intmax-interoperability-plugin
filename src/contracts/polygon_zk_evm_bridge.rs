use std::sync::Arc;

use ethers::{
    contract::abigen,
    core::types::{Address, U256},
    providers::Middleware,
    types::{H160, H256},
};

pub extern crate ethers;

abigen!(
    PolygonZkEVMBridgeContract,
    "./contracts/artifacts/contracts/PolygonZkEVMBridge.sol/PolygonZkEVMBridge.json"
);

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct RegisterEvent {
    /// topic 0
    pub offer_id: U256,
    /// topic 1
    pub maker: H160,
    /// topic 2
    pub taker: H256,

    pub asset_id: U256,
    pub maker_amount: U256,
    pub taker_token_address: H160,
    pub taker_amount: U256,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct ActivateEvent {
    /// topic 0
    pub flag_id: U256,
}

pub struct PolygonZkEVMBridgeContractWrapper<M> {
    pub contract: PolygonZkEVMBridgeContract<M>,
    pub address: Address,
    client: Arc<M>,
}

impl<M> std::ops::Deref for PolygonZkEVMBridgeContractWrapper<M> {
    type Target = PolygonZkEVMBridgeContract<M>;

    fn deref(&self) -> &Self::Target {
        &self.contract
    }
}

impl<M: Middleware> PolygonZkEVMBridgeContractWrapper<M> {
    pub fn new(contract_address: Address, client: Arc<M>) -> Self {
        Self {
            contract: PolygonZkEVMBridgeContract::new(contract_address, client.clone()),
            address: contract_address,
            client,
        }
    }

    // pub async fn get_register_events(
    //     &self,
    //     topic1: Vec<H256>,
    // ) -> anyhow::Result<Vec<RegisterEvent>> {
    //     // Register(offerId, maker, taker, makerAssetId, makerAmount, takerTokenAddress, takerAmount)
    //     let filter = Filter::new()
    //         .address(self.address)
    //         .event("Register(uint256,address,bytes32,uint256,uint256,address,uint256)")
    //         .topic1(topic1.clone())
    //         .from_block(0);
    //     let logs = self
    //         .client
    //         .get_logs(&filter)
    //         .await
    //         .map_err(|err| anyhow::anyhow!("{}", err))
    //         .unwrap();
    //     let logs = logs
    //         .into_iter()
    //         .filter_map(|log| {
    //             dbg!(&log);
    //             if !topic1.iter().any(|topic| topic == &log.topics[1]) {
    //                 return None;
    //             }

    //             let offer_id = U256::from_big_endian(log.topics[1].as_bytes());
    //             let maker = H160::from(log.topics[2]);
    //             let taker = log.topics[3];
    //             dbg!(&log.data);
    //             let asset_id = U256::from_big_endian(&log.data[0..32]);
    //             let maker_amount = U256::from_big_endian(&log.data[32..64]);
    //             let taker_token_address = H160::from(H256::from_slice(&log.data[64..96]));
    //             let taker_amount = U256::from_big_endian(&log.data[96..128]);

    //             Some(RegisterEvent {
    //                 offer_id,
    //                 maker,
    //                 taker,
    //                 asset_id,
    //                 maker_amount,
    //                 taker_token_address,
    //                 taker_amount,
    //             })
    //         })
    //         .collect::<Vec<_>>();

    //     Ok(logs)
    // }

    // pub async fn get_activate_events(&self) -> anyhow::Result<Vec<ActivateEvent>> {
    //     let filter = Filter::new()
    //         .address(self.address)
    //         .event("Activate(uint256)")
    //         .from_block(0);
    //     let logs = self
    //         .client
    //         .get_logs(&filter)
    //         .await
    //         .map_err(|err| anyhow::anyhow!("{}", err))?;
    //     let logs = logs
    //         .into_iter()
    //         .map(|log| {
    //             let flag_id = U256::from_big_endian(log.topics[1].as_bytes());

    //             ActivateEvent { flag_id }
    //         })
    //         .collect::<Vec<_>>();

    //     Ok(logs)
    // }
}

#[cfg(test)]
mod tests {
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

    use super::*;

    #[tokio::test]
    async fn test_polygon_zk_evm_bridge_l1() {
        let _ = dotenv().ok();
        let secret_key =
            std::env::var("PRIVATE_KEY").expect("PRIVATE_KEY must be set in .env file");
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
        let client = SignerMiddleware::new(provider, wallet);
        let client = Arc::new(client);

        let contract_address: Address = "0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7"
            .parse()
            .unwrap();
        let contract = PolygonZkEVMBridgeContractWrapper::new(contract_address, client);

        // let next_flag_id: U256 = contract.bridge_asset().call().await.unwrap();
        // dbg!(next_flag_id);

        // println!("start bridge_asset()");
        // {
        //     let destination_network = 1;
        //     let destination_address = my_account;
        //     let amount = 100000000000000000u128.into();
        //     let token = "0x0000000000000000000000000000000000000000"
        //         .parse()
        //         .unwrap(); // ETH
        //     let force_update_global_exit_root = true;
        //     let permit_data = "0x".parse().unwrap();
        //     contract
        //         .bridge_asset(
        //             destination_network,
        //             destination_address,
        //             amount,
        //             token,
        //             force_update_global_exit_root,
        //             permit_data,
        //         )
        //         .send()
        //         .await
        //         .unwrap();
        // }
        // println!("end bridge_asset()");

        println!("start bridge_message()");
        {
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
                .unwrap();
        }
        println!("end bridge_message()");

        // let next_next_flag_id: U256 = contract.next_flag_id().await.unwrap();
        // assert_eq!(next_next_flag_id, next_flag_id + U256::from(1u8));

        // let is_registered = contract.is_registered(next_flag_id).await.unwrap();
        // assert!(is_registered);

        // let logs = contract.get_register_events().await.unwrap();
        // dbg!(logs);

        // println!("start activate()");
        // contract.test_activate(next_flag_id).send().await.unwrap();
        // println!("end activate()");

        // let logs = contract.get_activate_events().await.unwrap();
        // dbg!(logs);

        // let is_activated = contract.is_activated(next_flag_id).await.unwrap();
        // assert!(is_activated);
    }

    #[tokio::test]
    async fn test_polygon_zk_evm_bridge_l2() {
        let _ = dotenv().ok();
        let secret_key =
            std::env::var("PRIVATE_KEY").expect("PRIVATE_KEY must be set in .env file");

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

        let metadata = "0x22334455667788".parse().unwrap();
        let deposit_count = 37504u32;

        println!("start claim_message()");
        {
            // get `smt_proof` from https://bridge-api.public.zkevm-test.net/merkle-proof
            let smt_proof: [[u8; 32]; 32] = [
                "0x8c377799b00d9e200db30bda57f5883ac3459882381e4bb448c5066386af76e3",
                "0xbc13888b626e11e1adb95a0b69131a5e06bb5a01f844103a75a64edb9143286e",
                "0xe71c4bd4c52e0ba37f6be7a115078ea86e3112fd58057112294eeaec7e2c8ad1",
                "0xea9a28956044146a4f10fe195488b1862a312f1b0a870e0de509f319ccf37140",
                "0xdb9db9c48297f8a4926bfc02ea5363d9e08526bffeaf1339b304cf42bbbe91e2",
                "0x9f14da3b2d116f102d4012b91fb0be1547cdbde749b6dd34971ee532c147eacd",
                "0xdb2237d66d4176d847170a3f0dc984fe8c50fdff55f2389348912b9209107784",
                "0x2347778db672fa2f28ee08e5ac12f1d2dd24097299d392a5a9538e57c752a055",
                "0xc999d2683755cf1496ba4c8e597006938614c96063e2870d3a374c087535a8e6",
                "0xeedc25353da1369a6f93d04a9fefdcdda3b78a5ae30be6d35e81c03769800894",
                "0x837bcc88c558c70f496622e3e70ffdd3d91f275c39d6850d4feb1ff9e4e5ebac",
                "0xd39a66f1767feb3526ad9cd574081d8215b57b22ec2d0536f0116f2e5df9ea66",
                "0xc0a3ba4e318cca341f13bc7f605b0f79b32f062629d1718f527223044ddf42c9",
                "0x4d673970f547542102a5b521825cbe418d4ab96209a81b48285e3ea4c98ca3d1",
                "0x5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc",
                "0xda7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2",
                "0x2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f",
                "0xe1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a",
                "0x5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0",
                "0xb46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0",
                "0xc65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2",
                "0xf4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9",
                "0x5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377",
                "0x4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652",
                "0xcdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef",
                "0x0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d",
                "0xb8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0",
                "0x838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e",
                "0x662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e",
                "0x388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322",
                "0x93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735",
                "0x8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9",
            ]
            .map(|v| hex::decode(&v[2..]).unwrap().try_into().unwrap());
            let index = deposit_count;
            let mainnet_exit_root =
                hex::decode("f3a53d350934c7eaf17248d7757420c3892825d6e611c0140da2eaa150602780")
                    .unwrap()
                    .try_into()
                    .unwrap();
            let rollup_exit_root =
                hex::decode("3c1e53958be508740f7242abd040ed4ce379307378e2da074584bc72c8926b3f")
                    .unwrap()
                    .try_into()
                    .unwrap();
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
}
