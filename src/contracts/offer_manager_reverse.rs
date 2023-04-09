use std::sync::Arc;

use ethers::{
    contract::{abigen, builders::Event},
    core::types::{Address, U256},
    providers::Middleware,
    types::{H160, H256},
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
    pub taker: H160,

    pub taker_intmax_address: H256,
    pub taker_token_address: H160,
    pub taker_amount: U256,
    pub maker_intmax_address: H256,
    pub maker_asset_id: U256,
    pub maker_amount: U256,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct UnlockEvent {
    /// topic 0
    pub offer_id: U256,

    /// topic 1
    pub maker: H160,
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

    pub async fn get_register_events(
        &self,
        topic_offer_id: Option<Vec<H256>>,
        topic_taker: Option<Vec<H256>>,
    ) -> anyhow::Result<Vec<LockEvent>> {
        let filter: Event<M, OfferRegisteredFilter> = self
            .offer_registered_filter()
            .address(self.address.into())
            .from_block(0);
        let filter = if let Some(topic_offer_id) = topic_offer_id.clone() {
            filter.topic1(topic_offer_id)
        } else {
            filter
        };
        let filter = if let Some(topic_taker) = topic_taker.clone() {
            filter.topic2(topic_taker)
        } else {
            filter
        };

        let logs: Vec<OfferRegisteredFilter> = filter
            .query()
            .await
            .map_err(|err| anyhow::anyhow!("{}", err))?;
        let logs = logs
            .into_iter()
            .filter_map(|log| {
                {
                    let mut bytes = [0u8; 32];
                    log.offer_id.to_big_endian(&mut bytes);
                    let offer_id = H256::from(bytes);
                    if let Some(topic_offer_id) = topic_offer_id.clone() {
                        if !topic_offer_id.iter().any(|topic| topic == &offer_id) {
                            return None;
                        }
                    }
                    let taker = H256::from(log.taker);
                    if let Some(topic_taker) = topic_taker.clone() {
                        if !topic_taker.iter().any(|topic| topic == &taker) {
                            return None;
                        }
                    }
                }

                Some(LockEvent {
                    offer_id: log.offer_id,
                    taker: log.taker,
                    taker_intmax_address: H256::from(log.taker_intmax_address),
                    taker_token_address: log.taker_token_address,
                    taker_amount: log.taker_amount,
                    maker_intmax_address: H256::from(log.maker_intmax_address),
                    maker_asset_id: log.maker_asset_id,
                    maker_amount: log.maker_amount,
                })
            })
            .collect::<Vec<_>>();

        Ok(logs)
    }

    pub async fn get_activate_events(&self) -> anyhow::Result<Vec<UnlockEvent>> {
        // Activate(indexed offerId, indexed takerIntmax)
        let filter: Event<M, OfferActivatedFilter> = self
            .offer_activated_filter()
            .address(self.address.into())
            .from_block(0);
        let logs: Vec<OfferActivatedFilter> = filter
            .query()
            .await
            .map_err(|err| anyhow::anyhow!("{}", err))?;
        let logs = logs
            .into_iter()
            .map(|log| UnlockEvent {
                offer_id: log.offer_id,
                maker: log.maker,
            })
            .collect::<Vec<_>>();

        Ok(logs)
    }
}
