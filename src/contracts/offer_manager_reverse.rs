use std::sync::Arc;

use ethers::{
    contract::abigen,
    core::types::{Address, U256},
    providers::Middleware,
    types::H160,
};

abigen!(
    OfferManagerReverseContract,
    "./contracts/compiled-artifacts/contracts/OfferManagerReverse.sol/OfferManagerReverse.json"
);

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct LockEvent {
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
pub struct UnlockEvent {
    /// topic 0
    pub offer_id: U256,
}

pub struct OfferManagerReverseContractWrapper<M> {
    pub contract: OfferManagerReverseContract<M>,
    pub address: Address,
}

impl<M> std::ops::Deref for OfferManagerReverseContractWrapper<M> {
    type Target = OfferManagerReverseContract<M>;

    fn deref(&self) -> &Self::Target {
        &self.contract
    }
}

impl<M: Middleware> OfferManagerReverseContractWrapper<M> {
    pub fn new(contract_address: Address, client: Arc<M>) -> Self {
        Self {
            contract: OfferManagerReverseContract::new(contract_address, client),
            address: contract_address,
        }
    }

    // pub async fn get_register_events(
    //     &self,
    //     topic1: Vec<H256>,
    // ) -> anyhow::Result<Vec<RegisterEvent>> {
    //     let filter: Event<M, RegisterFilter> = self
    //         .register_filter()
    //         .address(self.address.into())
    //         .topic1(topic1.clone())
    //         .from_block(0);
    //     let logs: Vec<RegisterFilter> = filter
    //         .query()
    //         .await
    //         .map_err(|err| anyhow::anyhow!("{}", err))?;
    //     let logs = logs
    //         .into_iter()
    //         .filter_map(|log| {
    //             dbg!(&log);
    //             {
    //                 let mut bytes = [0u8; 32];
    //                 log.offer_id.to_big_endian(&mut bytes);
    //                 let offer_id = H256::from(bytes);
    //                 if !topic1.iter().any(|topic| topic == &offer_id) {
    //                     return None;
    //                 }
    //             }

    //             Some(RegisterEvent {
    //                 offer_id: log.offer_id,
    //                 maker: log.maker,
    //                 asset_id: log.maker_asset_id,
    //                 maker_amount: log.maker_amount,
    //                 taker_token_address: log.taker_token_address,
    //                 taker_amount: log.taker_amount,
    //             })
    //         })
    //         .collect::<Vec<_>>();

    //     Ok(logs)
    // }

    // pub async fn get_activate_events(&self) -> anyhow::Result<Vec<ActivateEvent>> {
    //     // Activate(indexed offerId, indexed takerIntmax)
    //     let filter: Event<M, ActivateFilter> = self
    //         .activate_filter()
    //         .address(self.address.into())
    //         .from_block(0);
    //     let logs: Vec<ActivateFilter> = filter
    //         .query()
    //         .await
    //         .map_err(|err| anyhow::anyhow!("{}", err))?;
    //     let logs = logs
    //         .into_iter()
    //         .map(|log| ActivateEvent {
    //             offer_id: log.offer_id,
    //             taker: H256::from(log.taker_intmax),
    //         })
    //         .collect::<Vec<_>>();

    //     Ok(logs)
    // }
}
