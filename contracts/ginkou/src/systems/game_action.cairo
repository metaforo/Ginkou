use starknet::{ContractAddress};

#[starknet::interface]
trait IGameAction<TConstactState> {
    fn create(
        self: @TConstactState,
        preparation_phase: u64,
        collect_interval: u64,
        end_block: u64,
        erc_hash: felt252,
    ) -> u64;
}

#[dojo::contract]
mod game_actions {
    use starknet::{ContractAddress};
    use super::IGameAction;

    use Ginkou::components::game::{Game, GameInfo, GameTracker, GameStatus};
    use Ginkou::constants::GAME_CONFIG;
    use Ginkou::utils;

    #[external(v0)]
    impl GameActionImpl of IGameAction<ContractState> {
        fn create(
            self: @ContractState,
            preparation_phase: u64,
            collect_interval: u64,
            end_block: u64,
            erc_hash: felt252,
        ) -> u64 {
            let world = self.world_dispatcher.read();

            let mut game_tracker = get!(world, GAME_CONFIG, (GameTracker));
            let game_id = game_tracker.count + 1;

            let start_block = utils::get_block_number();
            let status = GameStatus::preparing;

            let game = Game {
                game_id,
                start_block,
                preparation_phase,
                collect_interval,
                end_block,
                erc_hash,
                status,
            };
            let game_tracker = GameTracker { id: GAME_CONFIG, count: game_id, last_result: '' };

            let game_info = GameInfo { game_id, player_count: 0 };

            set!(world, (game, game_tracker, game_info));

            game_id
        }
    }
}
