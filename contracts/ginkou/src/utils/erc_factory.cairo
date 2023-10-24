use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherImpl, IERC20DispatcherTrait};
use zeroable::Zeroable;
use starknet::class_hash::ClassHash;
use starknet::{
        ContractAddress, get_contract_address, deploy_syscall
    };

use Ginkou::components::erc_token::ErcToken;
use Ginkou::components::game::{Game, GameStatus, GameInfo, GameTrait, GameTracker};

fn create_wrap_address(world: IWorldDispatcher, game_id: u64, resource_type: u64, name: felt252, symbol: felt252) {
    let exist_erc = get!(world, (game_id, resource_type), (ErcToken));
    assert(exist_erc.status == 0, 'erc already exist');
    let game = get!(world, (game_id), (Game));
    let wrap_hash = game.erc_hash;
    let mut calldata = Default::default();
    let owner = get_contract_address();
    owner.serialize(ref calldata);
    name.serialize(ref calldata);
    symbol.serialize(ref calldata);

    let (contract_addr, _) = deploy_syscall(wrap_hash.try_into().unwrap(), 0, calldata.span(), false).unwrap();
    
    let new_erc = ErcToken {
        game_id,
        resource_type,
        contract_addr,
        status: 1,
    };
    set!(world, (new_erc));
}