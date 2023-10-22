use starknet::ContractAddress;
#[starknet::interface]
trait IPlayerAction<TContractState> {
    fn create(self: @TContractState, game_id: u64, name: felt252) -> u64;

    fn collect_resource(self: @TContractState, game_id: u64, player_id: u64) -> u64;
}

#[dojo::contract]
mod player_actions {
    use starknet::{
        ContractAddress, get_caller_address, contract_address_const, call_contract_syscall,
        get_contract_address
    };
    use box::BoxTrait;
    use traits::{Into, TryInto};
    use super::IPlayerAction;

    use Ginkou::components::game::{Game, GameStatus, GameInfo, GameTrait, GameTracker};
    use Ginkou::components::player::{Player, PlayerInfo, PlayerResource};
    use Ginkou::constants::{GAME_CONFIG, ResourceType};
    use Ginkou::utils;

    #[external(v0)]
    impl PlayerActionImpl of IPlayerAction<ContractState> {
        fn create(self: @ContractState, game_id: u64, name: felt252) -> u64 {
            assert(name != '', 'name length must larget then 0');

            let world = self.world_dispatcher.read();
            let (mut game, mut game_info) = get!(world, game_id, (Game, GameInfo));
            game.assert_can_create_player(world);

            let owner = get_caller_address();
            let block_number = utils::get_block_number();

            game_info.player_count += 1;
            let player_id = game_info.player_count;
            let existed_player = get!(world, (game_id, owner), (Player));
            assert(existed_player.player_id == 0, 'Player has existed!');

            let player = Player { game_id, owner, player_id, name, join_block: block_number };

            // TODO: create random resource
            // init start resource
            let player_info = PlayerInfo {
                game_id,
                player_id,
                owner,
                name,
                last_collect_block: block_number,
                transaction_count: 0,
            };

            set!(world, (player, player_info));

            player_id
        }

        fn collect_resource(self: @ContractState, game_id: u64, player_id: u64,) -> u64 {
            let world = self.world_dispatcher.read();
            let mut game = get!(world, game_id, Game);
            game.assert_is_playing(world);

            let owner = get_caller_address();
            let block_number = utils::get_block_number();

            let mut player_info = get!(world, (game_id, player_id), PlayerInfo);
            assert(owner == player_info.owner, 'Not owner');
            assert(
                player_info.last_collect_block + game.collect_interval >= block_number,
                'collect too quick'
            );
            // TODO: collect resource and type should be random (now is 1)
            player_info.last_collect_block = block_number;
            let mut player_resource = get!(world, (game_id, player_id, 1), (PlayerResource));
            player_resource.amount += 1;

            set!(world, (player_info, player_resource));

            0
        }
    }
}
