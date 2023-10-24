use starknet::{ContractAddress};

#[derive(Model, Copy, Drop, Print, Serde, SerdeLen)]
struct ErcToken {
    #[key]
    game_id: u64,
    #[key]
    resource_type: u64,
    contract_addr: ContractAddress,
    status: u64,
}