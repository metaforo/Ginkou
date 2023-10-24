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
    last_collect_block: u64,
    transaction_count: u64,
}

#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct PlayerResource {
    #[key]
    game_id: u64,
    #[key]
    player_id: u64,
    #[key]
    resource_id: u64,
    amount: u64,
}
