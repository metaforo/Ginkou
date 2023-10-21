use starknet::ContractAddress;
#[starknet::interface]
trait IPlayerAction<TContractState> {
    fn create(self: @TContractState, game_id: u64, name: felt252) -> u64;

    fn collect_resource(self: @TContractState, game_id: u64, player_id: u64) -> u64;

    fn withdraw(
        self: @TContractState, game_id: u64, player_id: u64, resource_type: u64, amount: u64
    ) -> bool;
    fn deposit(
        self: @TContractState, game_id: u64, player_id: u64, resource_type: u64, amount: u64
    ) -> bool;
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

    use Bank::components::game::{Game, GameStatus, GameInfo, GameTrait, GameTracker};
    use Bank::components::player::{Player, PlayerInfo};
    use Bank::constants::{GAME_CONFIG, ResourceType};
    use Bank::utils;

    use openzeppelin::token::erc20::interface::{
        IERC20, IERC20Dispatcher, IERC20DispatcherImpl, IERC20DispatcherTrait
    };

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
                gold: 10,
                silver: 10,
                iron: 100,
                copper: 100,
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
            // TODO: collect resource and type should be random

            player_info.last_collect_block = block_number;
            player_info.gold += 2;
            player_info.silver += 2;

            set!(world, (player_info));

            0
        }

        fn withdraw(
            self: @ContractState, game_id: u64, player_id: u64, resource_type: u64, amount: u64
        ) -> bool {
            let world = self.world_dispatcher.read();
            let mut game = get!(world, game_id, Game);
            game.assert_is_playing(world);

            let owner = get_caller_address();
            let mut player_info = get!(world, (game_id, player_id), PlayerInfo);
            assert(player_info.owner == owner, 'Not owner');

            let mut contract_addr: ContractAddress = contract_address_const::<0x0>();
            if (resource_type == ResourceType::gold) {
                assert(player_info.gold >= amount, 'Gold not enough');
                player_info.gold -= amount;
                contract_addr = game.gold_addr;
            } else if (resource_type == ResourceType::silver) {
                assert(player_info.silver >= amount, 'Silver not enough');
                player_info.silver -= amount;
                contract_addr = game.silver_addr;
            } else {
                assert(false, 'Not implement');
            }

            let erc20 = IERC20Dispatcher { contract_address: contract_addr };
            let result = erc20.transfer(recipient: owner, amount: amount.into());

            set!(world, (player_info));
            true
        }
        fn deposit(
            self: @ContractState, game_id: u64, player_id: u64, resource_type: u64, amount: u64
        ) -> bool {
            let world = self.world_dispatcher.read();
            let mut game = get!(world, game_id, Game);
            game.assert_is_playing(world);

            let owner = get_caller_address();
            let mut player_info = get!(world, (game_id, player_id), PlayerInfo);
            assert(player_info.owner == owner, 'Not owner');

            let mut contract_addr: ContractAddress = contract_address_const::<0x0>();
            if (resource_type == ResourceType::gold) {
                contract_addr = game.gold_addr;
            } else if (resource_type == ResourceType::silver) {
                contract_addr = game.silver_addr;
            } else {
                assert(false, 'Not implement');
            }

            let erc20 = IERC20Dispatcher { contract_address: contract_addr };
            let result = erc20
                .transfer_from(
                    sender: owner, recipient: get_contract_address(), amount: amount.into()
                );

            assert(result, 'Failed to deposit');

            if (resource_type == ResourceType::gold) {
                player_info.gold += amount;
            } else if (resource_type == ResourceType::silver) {
                player_info.silver += amount;
            }
            player_info.transaction_count += 1;

            set!(world, (player_info));

            true
        }
    }
}
