use starknet::ContractAddress;

#[starknet::interface]
trait IGinkouAction<TContractState> {
    fn create_resource(self: @TContractState, game_id: u64, resource_type: u64, name: felt252, symbol: felt252);

    fn withdraw(
        self: @TContractState, game_id: u64, player_id: u64, resource_type: u64, amount: u64
    ) -> bool;

    fn deposit(
        self: @TContractState, game_id: u64, player_id: u64, resource_type: u64, amount: u64
    ) -> bool;
}

#[dojo::contract]
mod ginkou_actions {
    use starknet::{
        ContractAddress, get_caller_address, contract_address_const, call_contract_syscall,
        get_contract_address
    };
    use box::BoxTrait;
    use traits::{Into, TryInto};
    use super::IGinkouAction;

    use Ginkou::components::erc_token::{ErcToken};
    use Ginkou::components::game::{Game, GameStatus, GameInfo, GameTrait, GameTracker};
    use Ginkou::components::player::{Player, PlayerInfo, PlayerResource};
    use Ginkou::constants::{GAME_CONFIG, ResourceType};
    use Ginkou::utils::erc_factory::create_wrap_address;

    use openzeppelin::token::erc20::interface::{
        IERC20, IERC20Dispatcher, IERC20DispatcherImpl, IERC20DispatcherTrait
    };

    #[external(v0)]
    impl GinkouActionImpl of IGinkouAction<ContractState> {

        fn create_resource(self: @ContractState, game_id: u64, resource_type: u64, name: felt252, symbol: felt252) {
            let world = self.world_dispatcher.read();
            let mut game = get!(world, game_id, Game);
            game.assert_can_create_erc(world);

            create_wrap_address(world, game_id, resource_type, name, symbol);
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

            let mut player_resource = get!(world, (game_id, player_id, resource_type), PlayerResource);
            // TODO: Don't check player resource amount for demo
            // assert(player_resource.amount >= amount, 'Resource not enough');
            // player_resource.amount -= amount;

            let erc = get!(world, (game_id, resource_type), ErcToken);
            assert(erc.status != 0, 'This resource not exist');
            let erc20 = IERC20Dispatcher { contract_address: erc.contract_addr };
            let result = erc20.transfer(recipient: owner, amount: amount.into());

            set!(world, (player_resource));
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

            let erc = get!(world, (game_id, resource_type), ErcToken);
            assert(erc.status != 0, 'This resource not exist');
            let erc20 = IERC20Dispatcher { contract_address: erc.contract_addr };
            let result = erc20
                .transfer_from(
                    sender: owner, recipient: get_contract_address(), amount: amount.into()
                );
            assert(result, 'Failed to deposit');
            
            let mut player_resource = get!(world, (game_id, player_id, resource_type), PlayerResource);
            player_resource.amount += amount;
            player_info.transaction_count += 1;

            set!(world, (player_info, player_resource));
            true
        }
    }
}
