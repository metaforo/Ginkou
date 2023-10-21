use starknet::ContractAddress;

#[starknet::interface]
trait IGinkouAction<TContractState> {
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

    use Ginkou::components::game::{Game, GameStatus, GameInfo, GameTrait, GameTracker};
    use Ginkou::components::player::{Player, PlayerInfo};
    use Ginkou::constants::{GAME_CONFIG, ResourceType};
    use Ginkou::utils;

    use openzeppelin::token::erc20::interface::{
        IERC20, IERC20Dispatcher, IERC20DispatcherImpl, IERC20DispatcherTrait
    };

    #[external(v0)]
    impl GinkouActionImpl of IGinkouAction<ContractState> {
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
