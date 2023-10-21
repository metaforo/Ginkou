#[starknet::contract]
mod WSilverToken {
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin::access::ownable::Ownable;
    use openzeppelin::token::erc20::erc20::ERC20;
    use openzeppelin::token::erc20::erc20::ERC20::InternalTrait;
    use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher};
    use openzeppelin::token::erc20::interface::IERC20CamelOnly;

    #[storage]
    struct Storage {
        _admin_addr: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        let mut unsafe_ownable = Ownable::unsafe_new_contract_state();
        Ownable::InternalImpl::initializer(ref unsafe_ownable, owner);

        let name = 'WSilverToken';
        let symbol = 'WSilver';

        let mut unsafe_state = ERC20::unsafe_new_contract_state();
        ERC20::InternalImpl::initializer(ref unsafe_state, name, symbol);
        ERC20::InternalImpl::_mint(ref unsafe_state, owner, 0xFFFFFFFFFFFFFFF);
    }

    #[external(v0)]
    fn change_admin(ref self: ContractState, admin_addr: ContractAddress) {
        // Set permissions with Ownable
        let unsafe_ownable = Ownable::unsafe_new_contract_state();
        Ownable::InternalImpl::assert_only_owner(@unsafe_ownable);
        self._admin_addr.write(admin_addr);
    }

    #[external(v0)]
    fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
        let admin: ContractAddress = self._admin_addr.read();
        let caller: ContractAddress = get_caller_address();
        assert(!caller.is_zero(), 'Caller is the zero address');
        if (caller != admin) {
            // Set permissions with Ownable
            let unsafe_ownable = Ownable::unsafe_new_contract_state();
            Ownable::InternalImpl::assert_only_owner(@unsafe_ownable);
        }
        // Mint tokens if called by the contract owner
        let mut unsafe_erc20 = ERC20::unsafe_new_contract_state();
        ERC20::InternalImpl::_mint(ref unsafe_erc20, recipient, amount);
    }

    // below is from openzeppelin

    //
    // External
    //

    #[external(v0)]
    impl ERC20Impl of IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.name()
        }

        fn symbol(self: @ContractState) -> felt252 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.symbol()
        }

        fn decimals(self: @ContractState) -> u8 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.decimals()
        }

        fn total_supply(self: @ContractState) -> u256 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.total_supply()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.balance_of(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.allowance(owner, spender)
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let mut erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.transfer(recipient, amount)
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let mut erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.transfer_from(sender, recipient, amount)
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let mut erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.approve(spender, amount)
        }
    }

    #[external(v0)]
    impl ERC20CamelOnlyImpl of IERC20CamelOnly<ContractState> {
        fn totalSupply(self: @ContractState) -> u256 {
            ERC20Impl::total_supply(self)
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            ERC20Impl::balance_of(self, account)
        }

        fn transferFrom(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            ERC20Impl::transfer_from(ref self, sender, recipient, amount)
        }
    }
}
