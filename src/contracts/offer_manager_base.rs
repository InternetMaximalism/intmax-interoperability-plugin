use std::{collections::HashSet, sync::Arc};

use ethers::{
    contract::{abigen, builders::Event},
    core::types::Address,
    providers::Middleware,
};

abigen!(
    OfferManagerBaseContract,
    "./contracts/compiled-artifacts/contracts/OfferManagerBaseInterface.sol/OfferManagerBaseInterface.json"
);

abigen!(
    TokenAllowListContract,
    "./contracts/compiled-artifacts/contracts/utils/TokenAllowListInterface.sol/TokenAllowListInterface.json"
);

#[derive(Clone, Debug)]
pub struct TokenAllowListContractWrapper<M> {
    pub contract: TokenAllowListContract<M>,
    pub address: Address,
}

impl<M> std::ops::Deref for TokenAllowListContractWrapper<M> {
    type Target = TokenAllowListContract<M>;

    fn deref(&self) -> &Self::Target {
        &self.contract
    }
}

impl<M: Middleware> TokenAllowListContractWrapper<M> {
    pub fn new(contract_address: Address, client: Arc<M>) -> Self {
        Self {
            contract: TokenAllowListContract::new(contract_address, client),
            address: contract_address,
        }
    }

    pub async fn get_token_allow_list(&self, latest_block: u64) -> anyhow::Result<Vec<Address>> {
        let from_block_num = if latest_block < 9900 {
            0
        } else {
            latest_block - 9900
        };
        let filter: Event<M, TokenAllowListUpdatedFilter> = self
            .token_allow_list_updated_filter()
            .address(self.address.into())
            .from_block(from_block_num);

        let logs: Vec<TokenAllowListUpdatedFilter> = filter
            .query()
            .await
            .map_err(|err| anyhow::anyhow!("{}", err))?;
        println!("logs.len() = {}", logs.len());
        let mut result = HashSet::new();
        for log in logs {
            if log.is_allowed {
                result.insert(log.token);
            } else {
                result.remove(&log.token);
            }
        }

        let mut result = result.into_iter().collect::<Vec<_>>();
        result.sort();

        Ok(result)
    }
}
