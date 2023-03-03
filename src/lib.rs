use serde::Deserialize;
use web3::{
    contract::{Contract, Options},
    types::{TransactionReceipt, H160, U256},
    Transport,
};

extern crate tokio;

#[derive(Clone, Debug, PartialEq, Deserialize)]
pub struct HardHatSolidityArtifacts {
    #[serde(rename = "contractName")]
    pub contract_name: String,
    pub abi: web3::ethabi::Contract,
    pub bytecode: String,
    #[serde(rename = "deployedBytecode")]
    pub deployed_bytecode: String,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct RegisterEvent {
    /// topic 0
    pub flag_id: U256,
    /// topic 1
    pub recipient: H160,
    /// topic 2
    pub asset_id: U256,
    pub amount: U256,
}

#[derive(Copy, Clone, Debug, PartialEq, Eq)]
pub struct ActivateEvent {
    /// topic 0
    pub flag_id: U256,
}

pub struct FlagManagerContract<T: Transport> {
    pub contract: Contract<T>,
    // eth: web3::api::Eth<T>,
}

impl<T: Transport> std::ops::Deref for FlagManagerContract<T> {
    type Target = Contract<T>;

    fn deref(&self) -> &Self::Target {
        &self.contract
    }
}

pub fn send_options() -> Options {
    Options::with(|opt| {
        opt.gas_price = Some(1_000_000_000u32.into());
        opt.gas = Some(30_000_000u32.into());
    })
}

impl<T: Transport> FlagManagerContract<T> {
    pub fn new(web3: &web3::Web3<T>, contract_address: H160) -> Self {
        let artifacts: HardHatSolidityArtifacts = serde_json::from_str(include_str!(
            "../contracts/artifacts/contracts/FlagManager.test.sol/FlagManagerTest.json"
        ))
        .unwrap();

        Self {
            contract: Contract::new(web3.eth(), contract_address, artifacts.abi),
        }
    }

    pub async fn next_flag_id(&self) -> web3::contract::Result<U256> {
        self.query("nextFlagId", (), None, Options::default(), None)
            .await
    }

    pub async fn is_registered(&self, flag_id: U256) -> web3::contract::Result<bool> {
        self.query("isRegistered", (flag_id,), None, Options::default(), None)
            .await
    }

    pub async fn is_activated(&self, flag_id: U256) -> web3::contract::Result<bool> {
        self.query("isActivated", (flag_id,), None, Options::default(), None)
            .await
    }

    pub async fn register(
        &self,
        signer_key: impl web3::signing::Key,
        recipient: H160,
        asset_id: U256,
        amount: U256,
    ) -> web3::Result<TransactionReceipt> {
        let gas = self
            .estimate_gas(
                "register",
                (recipient, asset_id, amount),
                signer_key.address(),
                Options::default(),
            )
            .await
            .unwrap();
        dbg!(gas);
        self.signed_call_with_confirmations(
            "register",
            (recipient, asset_id, amount),
            Options::with(|opt| {
                opt.gas = Some(gas);
            }),
            0,
            signer_key,
        )
        .await
    }

    pub async fn activate(
        &self,
        signer_key: impl web3::signing::Key,
        flag_id: U256,
    ) -> web3::Result<TransactionReceipt> {
        let gas = self
            .estimate_gas(
                "testActivate",
                (flag_id,),
                signer_key.address(),
                Options::default(),
            )
            .await
            .unwrap();
        dbg!(gas);
        self.signed_call_with_confirmations(
            "testActivate",
            (flag_id,),
            Options::with(|opt| {
                opt.gas = Some(gas);
            }),
            0,
            signer_key,
        )
        .await
    }

    pub async fn get_register_events(&self) -> web3::contract::Result<Vec<RegisterEvent>> {
        let logs: Vec<(U256, H160, U256, U256)> = self.events("Register", (), (), ()).await?;
        let logs = logs
            .into_iter()
            .map(|v| RegisterEvent {
                flag_id: v.0,
                recipient: v.1,
                asset_id: v.2,
                amount: v.3,
            })
            .collect::<Vec<_>>();

        Ok(logs)
    }

    pub async fn get_activate_events(&self) -> web3::contract::Result<Vec<ActivateEvent>> {
        let logs: Vec<(U256,)> = self.events("Activate", (), (), ()).await?;
        let logs = logs
            .into_iter()
            .map(|v| ActivateEvent { flag_id: v.0 })
            .collect::<Vec<_>>();

        Ok(logs)
    }
}

#[cfg(test)]
mod tests {
    use std::str::FromStr;

    use secp256k1::key::SecretKey;
    use web3::{
        signing::{Key, SecretKeyRef},
        types::U256,
    };

    use super::*;

    #[tokio::test]
    async fn it_works() {
        let secret_key =
            SecretKey::from_str("ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
                .unwrap();
        let rpc_url = "http://localhost:8545";

        let transport = web3::transports::Http::new(rpc_url).unwrap();
        let web3 = web3::Web3::new(transport);

        // let accounts = web3.eth().accounts().await.unwrap();
        // dbg!(&accounts);

        let my_account = SecretKeyRef::new(&secret_key).address();

        // // Deploying a contract
        // let deployer_account = accounts[0];
        // let contract = Contract::deploy(web3.eth(), artifacts.abi)?
        //     .confirmations(0)
        //     .options(Options::with(|_opt| {
        //         // _opt.value = Some(5u32.into());x
        //         // _opt.gas_price = Some(1_000_000_000u32.into());
        //         // _opt.gas = Some(30_000_000u32.into());
        //     }))
        //     .execute(artifacts.bytecode, (), deployer_account)
        //     .await?;

        let contract_address: H160 = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
            .parse()
            .unwrap();
        let contract = FlagManagerContract::new(&web3, contract_address);
        let next_flag_id: U256 = contract.next_flag_id().await.unwrap();
        // assert_eq!(next_flag_id, 1u32.into());

        println!("start register()");
        let _res = contract
            .register(
                SecretKeyRef::new(&secret_key),
                my_account,
                1u8.into(),
                100u64.into(),
            )
            .await
            .unwrap();
        println!("end register()");

        let next_next_flag_id: U256 = contract.next_flag_id().await.unwrap();
        assert_eq!(next_next_flag_id, next_flag_id + U256::from(1u8));

        let is_registered = contract.is_registered(next_flag_id).await.unwrap();
        assert!(is_registered);

        let logs = contract.get_register_events().await.unwrap();
        dbg!(logs);

        println!("start activate()");
        let _res = contract
            .activate(SecretKeyRef::new(&secret_key), next_flag_id)
            .await
            .unwrap();
        println!("end activate()");

        let logs = contract.get_activate_events().await.unwrap();
        dbg!(logs);

        let is_activated = contract.is_activated(next_flag_id).await.unwrap();
        assert!(is_activated);
    }
}
