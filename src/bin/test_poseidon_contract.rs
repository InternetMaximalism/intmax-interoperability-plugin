use std::{sync::Arc, time::Duration};

use dotenv::dotenv;
use ethers::{
    contract::abigen,
    core::types::{Address, U256},
    middleware::SignerMiddleware,
    prelude::k256::ecdsa::SigningKey,
    providers::{Http, Provider},
    signers::LocalWallet,
    utils::secret_key_to_address,
};
#[cfg(feature = "test_poseidon")]
use plonky2::{
    field::{
        goldilocks_field::GoldilocksField,
        types::{Field, PrimeField64, Sample},
    },
    hash::{
        hash_types::HashOut,
        hashing::{compress, hash_n_to_m_no_pad},
        poseidon::PoseidonPermutation,
    },
    plonk::config::GenericHashOut,
};

abigen!(
    PoseidonContract,
    "./contracts/compiled-artifacts/contracts/utils/Poseidon.sol/GoldilocksPoseidon.json"
);

#[cfg(feature = "test_poseidon")]
type F = GoldilocksField;

#[cfg(not(feature = "test_poseidon"))]
fn main() {}

#[cfg(feature = "test_poseidon")]
#[tokio::main]
async fn main() {
    let _ = dotenv().ok();
    let rpc_url = "http://localhost:8545";
    let chain_id = 31337;

    let provider = Provider::<Http>::try_from(rpc_url)
        .unwrap()
        .interval(Duration::from_millis(10u64));
    let rng = rand::thread_rng();
    let signer_key = SigningKey::random(rng);
    let my_account = secret_key_to_address(&signer_key);
    let wallet = LocalWallet::new_with_signer(signer_key, my_account, chain_id);
    let client = SignerMiddleware::new(provider, wallet);
    let client = Arc::new(client);

    let contract_address: Address = std::env::var("POSEIDON_CONTRACT_ADDRESS")
        .expect("POSEIDON_CONTRACT_ADDRESS must be set in .env file")
        .parse()
        .unwrap();
    let contract = PoseidonContract::new(contract_address, client);

    let mut i = 0usize;
    loop {
        if 10usize.pow(f64::log10(i as f64).ceil() as u32) == i {
            println!("i = {i}");
        }

        let left = HashOut::<F>::rand();
        let right = HashOut::<F>::rand();
        let expected_output = compress::<F, PoseidonPermutation<F>>(left, right);
        let mut solidity_left: [u8; 32] = left.to_bytes().try_into().unwrap();
        solidity_left.reverse();
        let mut solidity_right: [u8; 32] = right.to_bytes().try_into().unwrap();
        solidity_right.reverse();
        let mut solidity_output: [u8; 32] = contract
            .two_to_one(solidity_left, solidity_right)
            .call()
            .await
            .unwrap();
        solidity_output.reverse();
        let output = HashOut::<F>::from_bytes(&solidity_output);
        if output != expected_output {
            dbg!(left, right);
            assert_eq!(output, expected_output);
        }

        let num_inputs = rand::random::<usize>() % 25;
        let input = vec![(); num_inputs]
            .iter()
            .map(|_| F::rand())
            .collect::<Vec<_>>();
        let num_outputs: usize = 8;
        let expected_output = hash_n_to_m_no_pad::<F, PoseidonPermutation<F>>(&input, num_outputs);
        let solidity_input = input
            .iter()
            .map(|v| U256::from(v.to_canonical_u64()))
            .collect::<Vec<_>>();
        let solidity_output: Vec<U256> = contract
            .hash_n_to_m_no_pad(solidity_input, num_outputs.into())
            .call()
            .await
            .unwrap();
        let output = solidity_output
            .iter()
            .map(|v| F::from_canonical_u64(v.as_u64()))
            .collect::<Vec<_>>();

        if output != expected_output {
            dbg!(input);
            assert_eq!(output, expected_output);
        }

        i += 1;
    }
}
