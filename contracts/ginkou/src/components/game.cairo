use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use Ginkou::utils;
use starknet::{ContractAddress};

#[derive(Model, Copy, Drop, Print, Serde, SerdeLen)]
struct Game {
    #[key]
    game_id: u64,
    start_block: u64,
    preparation_phase: u64,
    collect_interval: u64,
    end_block: u64,
    erc_hash: felt252,
    status: u64,
}

#[derive(Model, Copy, Drop, Print, Serde, SerdeLen)]
struct GameTracker {
    #[key]
    id: u64,
    count: u64,
    last_result: felt252,
}

#[derive(Model, Copy, Drop, Print, Serde, SerdeLen)]
struct GameInfo {
    #[key]
    game_id: u64,
    player_count: u64,
}

mod GameStatus {
    const not_created: u64 = 0;
    const preparing: u64 = 1;
    const playing: u64 = 2;
    const ended: u64 = 3;
}

#[generate_trait]
impl GameImpl of GameTrait {
    fn assert_existed(self: Game) {
        assert(self.status != GameStatus::not_created, 'Game not exist');
    }

    fn refresh_status(ref self: Game, world: IWorldDispatcher) {
        self.assert_existed();
        // TODO: Don't check game status for demo.
        // let block_number = utils::get_block_number();
        // if self.status == GameStatus::preparing
        //     && (block_number - self.start_block) > self.preparation_phase {
        //     self.status = GameStatus::playing;
        //     set!(world, (self));
        // } else if self.status == GameStatus::playing && block_number > self.end_block {
        //     self.status = GameStatus::ended;
        //     set!(world, (self));
        // }
    }

    fn assert_can_create_player(ref self: Game, world: IWorldDispatcher) {
        self.refresh_status(world);
        // TODO: Don't check game status for demo.
        // assert(self.status != GameStatus::ended, 'Game has ended');
        // assert(self.status != GameStatus::playing, 'Prepare phase ended');
    }

    fn assert_can_create_erc(ref self: Game, world: IWorldDispatcher) {
        self.refresh_status(world);
        // TODO: Don't check game status for demo.
        // assert(self.status != GameStatus::ended, 'Game has ended');
        // assert(self.status != GameStatus::playing, 'Prepare phase ended');
    }

    fn assert_is_playing(ref self: Game, world: IWorldDispatcher) {
        self.assert_existed();
        // TODO: Don't check game status for demo.
        // self.refresh_status(world);
        // assert(self.status != GameStatus::ended, 'Game has ended');
        // assert(self.status == GameStatus::playing, 'Game has not started');
    }
}
