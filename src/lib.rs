use std::sync::Arc;

use ethers::{
    contract::abigen,
    core::types::{Address, U256},
    providers::Middleware,
    types::{Filter, H160, H256},
};

pub extern crate ethers;

abigen!(
    OfferManagerContract,
    "./contracts/artifacts/OfferManager.test.sol/OfferManagerTest.json"
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

pub struct OfferManagerContractWrapper<M> {
    pub contract: OfferManagerContract<M>,
    pub address: Address,
    client: Arc<M>,
}

impl<M> std::ops::Deref for OfferManagerContractWrapper<M> {
    type Target = OfferManagerContract<M>;

    fn deref(&self) -> &Self::Target {
        &self.contract
    }
}

impl<M: Middleware> OfferManagerContractWrapper<M> {
    pub fn new(contract_address: Address, client: Arc<M>) -> Self {
        Self {
            contract: OfferManagerContract::new(contract_address, client.clone()),
            address: contract_address,
            client,
        }
    }

    // pub async fn next_flag_id(&self) -> web3::contract::Result<U256> {
    //     self.query("nextFlagId", (), None, Options::default(), None)
    //         .await
    // }

    // pub async fn is_registered(&self, flag_id: U256) -> web3::contract::Result<bool> {
    //     self.query("isRegistered", (flag_id,), None, Options::default(), None)
    //         .await
    // }

    // pub async fn is_activated(&self, flag_id: U256) -> web3::contract::Result<bool> {
    //     self.query("isActivated", (flag_id,), None, Options::default(), None)
    //         .await
    // }

    // pub async fn register(
    //     &self,
    //     signer_key: impl web3::signing::Key,
    //     recipient: H160,
    //     asset_id: U256,
    //     amount: U256,
    // ) -> web3::Result<TransactionReceipt> {
    //     let gas = self
    //         .estimate_gas(
    //             "register",
    //             (recipient, asset_id, amount),
    //             signer_key.address(),
    //             Options::default(),
    //         )
    //         .await
    //         .unwrap();
    //     dbg!(gas);
    //     self.signed_call_with_confirmations(
    //         "register",
    //         (recipient, asset_id, amount),
    //         Options::with(|opt| {
    //             opt.gas = Some(gas);
    //         }),
    //         0,
    //         signer_key,
    //     )
    //     .await
    // }

    // pub async fn activate(
    //     &self,
    //     signer_key: impl web3::signing::Key,
    //     flag_id: U256,
    // ) -> web3::Result<TransactionReceipt> {
    //     let gas = self
    //         .estimate_gas(
    //             "testActivate",
    //             (flag_id,),
    //             signer_key.address(),
    //             Options::default(),
    //         )
    //         .await
    //         .unwrap();
    //     dbg!(gas);
    //     self.signed_call_with_confirmations(
    //         "testActivate",
    //         (flag_id,),
    //         Options::with(|opt| {
    //             opt.gas = Some(gas);
    //         }),
    //         0,
    //         signer_key,
    //     )
    //     .await
    // }

    pub async fn get_register_events(
        &self,
        topic1: Vec<H256>,
    ) -> anyhow::Result<Vec<RegisterEvent>> {
        // Register(offerId, maker, taker, makerAssetId, makerAmount, takerTokenAddress, takerAmount)
        let filter = Filter::new()
            .address(self.address)
            .event("Register(uint256,address,bytes32,uint256,uint256,address,uint256)")
            .topic1(topic1.clone())
            .from_block(0);
        let logs = self
            .client
            .get_logs(&filter)
            .await
            .map_err(|err| anyhow::anyhow!("{}", err))
            .unwrap();
        let logs = logs
            .into_iter()
            .filter_map(|log| {
                dbg!(&log);
                if !topic1.iter().any(|topic| topic == &log.topics[1]) {
                    return None;
                }

                let offer_id = U256::from_big_endian(log.topics[1].as_bytes());
                let maker = H160::from(log.topics[2]);
                let taker = log.topics[3];
                dbg!(&log.data);
                let asset_id = U256::from_big_endian(&log.data[0..32]);
                let maker_amount = U256::from_big_endian(&log.data[32..64]);
                let taker_token_address = H160::from(H256::from_slice(&log.data[64..96]));
                let taker_amount = U256::from_big_endian(&log.data[96..128]);

                Some(RegisterEvent {
                    offer_id,
                    maker,
                    taker,
                    asset_id,
                    maker_amount,
                    taker_token_address,
                    taker_amount,
                })
            })
            .collect::<Vec<_>>();

        Ok(logs)
    }

    pub async fn get_activate_events(&self) -> anyhow::Result<Vec<ActivateEvent>> {
        let filter = Filter::new()
            .address(self.address)
            .event("Activate(uint256)")
            .from_block(0);
        let logs = self
            .client
            .get_logs(&filter)
            .await
            .map_err(|err| anyhow::anyhow!("{}", err))?;
        let logs = logs
            .into_iter()
            .map(|log| {
                let flag_id = U256::from_big_endian(log.topics[1].as_bytes());

                ActivateEvent { flag_id }
            })
            .collect::<Vec<_>>();

        Ok(logs)
    }
}

#[cfg(test)]
mod tests {
    // use std::{sync::Arc, time::Duration};

    // use ethers::{
    //     core::types::{Address, U256},
    //     middleware::SignerMiddleware,
    //     prelude::k256::ecdsa::SigningKey,
    //     providers::{Http, Provider},
    //     signers::LocalWallet,
    //     utils::secret_key_to_address,
    // };

    // use super::*;

    // #[tokio::test]
    // async fn it_works() {
    //     let provider = Provider::<Http>::try_from("http://localhost:8545")
    //         .unwrap()
    //         .interval(Duration::from_millis(10u64));
    //     let secret_key = "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
    //     let chain_id = 31337;

    //     let signer_key = SigningKey::from_bytes(&hex::decode(secret_key).unwrap()).unwrap();
    //     let my_account = secret_key_to_address(&signer_key);
    //     let wallet = LocalWallet::new_with_signer(signer_key, my_account, chain_id);
    //     let client = SignerMiddleware::new(provider, wallet);
    //     let client = Arc::new(client);

    //     let contract_address: Address = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
    //         .parse()
    //         .unwrap();
    //     let contract = FlagManagerContractWrapper::new(contract_address, client);

    //     let next_flag_id: U256 = contract.next_flag_id().call().await.unwrap();
    //     dbg!(next_flag_id);

    //     println!("start register()");
    //     contract
    //         .test_register([0u8; 32], 1u8.into(), 100u64.into())
    //         .send()
    //         .await
    //         .unwrap();
    //     println!("end register()");

    //     let next_next_flag_id: U256 = contract.next_flag_id().await.unwrap();
    //     assert_eq!(next_next_flag_id, next_flag_id + U256::from(1u8));

    //     let is_registered = contract.is_registered(next_flag_id).await.unwrap();
    //     assert!(is_registered);

    //     let logs = contract.get_register_events().await.unwrap();
    //     dbg!(logs);

    //     println!("start activate()");
    //     contract.test_activate(next_flag_id).send().await.unwrap();
    //     println!("end activate()");

    //     let logs = contract.get_activate_events().await.unwrap();
    //     dbg!(logs);

    //     let is_activated = contract.is_activated(next_flag_id).await.unwrap();
    //     assert!(is_activated);
    // }
}
