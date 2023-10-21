fn get_block_number() -> u64 {
    starknet::get_block_info().unbox().block_number
}
