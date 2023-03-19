use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, Ord, PartialOrd)]
pub struct ResponsePolygonExitMerkleProof {
    pub proof: PolygonExitMerkleProof,
}

#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, Ord, PartialOrd)]
#[serde(
    from = "SerializablePolygonExitMerkleProof",
    into = "SerializablePolygonExitMerkleProof"
)]
pub struct PolygonExitMerkleProof {
    pub merkle_proof: [[u8; 32]; 32],
    pub main_exit_root: [u8; 32],
    pub rollup_exit_root: [u8; 32],
}

#[derive(Clone, Debug, PartialEq, Eq, Hash, Serialize, Deserialize, Ord, PartialOrd)]
struct SerializablePolygonExitMerkleProof {
    merkle_proof: [String; 32],
    main_exit_root: String,
    rollup_exit_root: String,
}

impl From<PolygonExitMerkleProof> for SerializablePolygonExitMerkleProof {
    fn from(value: PolygonExitMerkleProof) -> Self {
        let encode_bytes32 = |v: [u8; 32]| format!("0x{}", hex::encode(v));

        Self {
            merkle_proof: value.merkle_proof.map(encode_bytes32),
            main_exit_root: encode_bytes32(value.main_exit_root),
            rollup_exit_root: encode_bytes32(value.rollup_exit_root),
        }
    }
}

impl From<SerializablePolygonExitMerkleProof> for PolygonExitMerkleProof {
    fn from(value: SerializablePolygonExitMerkleProof) -> Self {
        let decode_bytes32 = |v: String| hex::decode(&v[2..]).unwrap().try_into().unwrap();

        Self {
            merkle_proof: value.merkle_proof.map(decode_bytes32),
            main_exit_root: decode_bytes32(value.main_exit_root),
            rollup_exit_root: decode_bytes32(value.rollup_exit_root),
        }
    }
}
