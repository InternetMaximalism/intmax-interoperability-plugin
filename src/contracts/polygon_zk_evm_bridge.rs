use std::sync::Arc;

use bytes::Buf;
use ethers::{
    contract::abigen,
    core::types::{Address, U256},
    providers::Middleware,
    types::{BlockNumber, Bytes, Filter, H160, H256},
};
use serde::{Deserialize, Serialize};

abigen!(
    PolygonZkEVMBridgeContract,
    "./contracts/compiled-artifacts/PolygonZkEVMBridge.sol/PolygonZkEVMBridge.json"
);

/// Parse `BridgeEvent(uint8,uint32,address,uint32,address,uint256,bytes,uint32)`.
#[derive(Clone, Debug, Default, PartialEq, Eq, Hash, Serialize, Deserialize, Ord, PartialOrd)]
pub struct BridgeEvent {
    pub leaf_type: u8,
    pub origin_network: u32,

    // Why this is without topic keyword?
    pub origin_address: H160,

    pub destination_network: u32,
    pub destination_address: H160,
    pub amount: U256,
    pub metadata: Bytes,
    pub deposit_count: u32,
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

    pub async fn get_bridge_events(
        &self,
        topic_origin_address: Vec<H160>,
        from_block: impl Into<BlockNumber>,
        to_block: impl Into<BlockNumber>,
    ) -> anyhow::Result<Vec<BridgeEvent>> {
        // BridgeEvent(leafType, originNetwork, originAddress, destinationNetwork, destinationAddress, amount, metadata, depositCount)
        let filter = Filter::new()
            .address(self.address)
            .event("BridgeEvent(uint8,uint32,address,uint32,address,uint256,bytes,uint32)")
            .from_block(from_block)
            .to_block(to_block);
        let logs = self
            .client
            .get_logs(&filter)
            .await
            .map_err(|err| anyhow::anyhow!("{}", err))
            .unwrap();
        let logs = logs
            .into_iter()
            .filter_map(|log| {
                let leaf_type = U256::from_big_endian(&log.data[0..32]).as_u32() as u8;
                let origin_network = U256::from_big_endian(&log.data[32..64]).as_u32();
                let origin_address = H160::from(H256::from_slice(&log.data[64..96]));
                let destination_network = U256::from_big_endian(&log.data[96..128]).as_u32();
                let destination_address = H160::from(H256::from_slice(&log.data[128..160]));
                let amount = U256::from_big_endian(&log.data[160..192]);
                let metadata_prefix = U256::from_big_endian(&log.data[192..224]);
                assert_eq!(metadata_prefix, 256.into());
                let deposit_count = U256::from_big_endian(&log.data[224..256]).as_u32();
                let metadata_length = U256::from_big_endian(&log.data[256..288]).as_usize();
                let mut data = log.data.0;
                data.advance(288);
                let metadata = data.slice(..metadata_length).into();

                if !topic_origin_address
                    .iter()
                    .any(|topic| topic == &origin_address)
                {
                    return None;
                }

                Some(BridgeEvent {
                    leaf_type,
                    origin_network,
                    origin_address,
                    destination_network,
                    destination_address,
                    amount,
                    metadata,
                    deposit_count,
                })
            })
            .collect::<Vec<_>>();

        Ok(logs)
    }
}
