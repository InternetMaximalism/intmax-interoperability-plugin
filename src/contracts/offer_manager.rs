use std::sync::Arc;

use ethers::{
    contract::abigen,
    core::types::{Address, U256},
    providers::Middleware,
    types::{Filter, H160, H256},
};

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

    pub asset_id: U256,
    pub maker_amount: U256,
    pub taker_token_address: H160,
    pub taker_amount: U256,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct ActivateEvent {
    /// topic 0
    pub offer_id: U256,

    /// topic 1
    pub taker: H256,
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

    pub async fn get_register_events(
        &self,
        topic1: Vec<H256>,
    ) -> anyhow::Result<Vec<RegisterEvent>> {
        // Register(indexed offerId, indexed maker, makerIntmax, makerAssetId, makerAmount, taker, takerTokenAddress, takerAmount)
        let filter = Filter::new()
            .address(self.address)
            .event("Register(uint256,address,bytes32,uint256,uint256,address,address,uint256)")
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
                dbg!(&log.data);
                let maker_asset_id = U256::from_big_endian(&log.data[32..64]);
                let maker_amount = U256::from_big_endian(&log.data[64..96]);
                let taker_token_address = H256::from_slice(&log.data[128..160]).into();
                let taker_amount = U256::from_big_endian(&log.data[160..192]);

                Some(RegisterEvent {
                    offer_id,
                    maker,
                    asset_id: maker_asset_id,
                    maker_amount,
                    taker_token_address,
                    taker_amount,
                })
            })
            .collect::<Vec<_>>();

        Ok(logs)
    }

    pub async fn get_activate_events(&self) -> anyhow::Result<Vec<ActivateEvent>> {
        // Activate(indexed offerId, indexed takerIntmax)
        let filter = Filter::new()
            .address(self.address)
            .event("Activate(uint256,bytes32)")
            .from_block(0);
        let logs = self
            .client
            .get_logs(&filter)
            .await
            .map_err(|err| anyhow::anyhow!("{}", err))?;
        let logs = logs
            .into_iter()
            .map(|log| {
                let offer_id = U256::from_big_endian(log.topics[1].as_bytes());
                let taker = log.topics[2];

                ActivateEvent { offer_id, taker }
            })
            .collect::<Vec<_>>();

        Ok(logs)
    }
}
