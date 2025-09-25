module relynk::mock_usdc {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::string;

    /// Token type (6 desimal)
    struct MockUSDC has store {}

    /// store capabilities on @relynk
    struct Caps has key {
        mint: coin::MintCapability<MockUSDC>,
        burn: coin::BurnCapability<MockUSDC>,
        freeze: coin::FreezeCapability<MockUSDC>,
    }

    const E_NOT_AUTHORIZED: u64 = 1;

    // Auto initialize once (admin @relynk)
    fun init_module(admin: &signer) {
        let who = signer::address_of(admin);
        assert!(who == @relynk, E_NOT_AUTHORIZED);

            let (burn, freeze, mint) = coin::initialize<MockUSDC>(
                admin,
                string::utf8(b"Mock USDC"),
                string::utf8(b"mUSDC"),
                6,      // decimals
                false   // monitor_supply
            );
            move_to(admin, Caps { mint, burn, freeze });
    }

    /// Register CoinStore<MockUSDC> (must be able to receive)
    public entry fun register(user: &signer) {
        if (!coin::is_account_registered<MockUSDC>(signer::address_of(user))) {
            coin::register<MockUSDC>(user);
        }
    }

    /// Mint to address (admin @relynk)
    public entry fun mint_to(admin: &signer, to: address, amount: u64) acquires Caps {
        let who = signer::address_of(admin);
        assert!(who == @relynk, E_NOT_AUTHORIZED);
        let caps = borrow_global<Caps>(@relynk);
        let coins = coin::mint<MockUSDC>(amount, &caps.mint);
        coin::deposit<MockUSDC>(to, coins);
    }

    /// Transfer (sender signs themselves)
    public entry fun transfer(sender: &signer, to: address, amount: u64) {
        // sender/receiver must be registered CoinStore<MockUSDC>
        coin::transfer<MockUSDC>(sender, to, amount);
    }

    /// View balance (optional)
    #[view]
    public fun balance_of(owner: address): u64 {
        if (!coin::is_account_registered<MockUSDC>(owner)) return 0;
        coin::balance<MockUSDC>(owner)
    }
}
