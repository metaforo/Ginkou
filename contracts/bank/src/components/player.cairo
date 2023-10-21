use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct Player {
    #[key]
    game_id: u64,
    #[key]
    owner: ContractAddress,
    player_id: u64,
    name: felt252,
    join_block: u64,
}

#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct PlayerInfo {
    #[key]
    game_id: u64,
    #[key]
    player_id: u64,
    owner: ContractAddress,
    name: felt252,
    gold: u64,
    silver: u64,
    iron: u64,
    copper: u64,
    last_collect_block: u64,
    transaction_count: u64,
}
