module relynk::supported_tokens {
    use std::signer;
    use aptos_std::table::{Self as table, Table};
    use aptos_std::type_info::{Self as type_info, TypeInfo};
    use aptos_framework::coin;

    /// Errors
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_ALREADY_INIT: u64 = 2;
    const E_NOT_SUPPORTED: u64 = 3;
    const E_NOT_INITIALIZED: u64 = 4;

    /// Resource for storing token allowlist
    struct SupportedTokens has key {
        allowed: Table<TypeInfo, bool>,
    }

    /// Initialize once (published at @relynk)
    public entry fun init_supported_tokens(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @relynk, E_NOT_AUTHORIZED);
        assert!(!exists<SupportedTokens>(admin_addr), E_ALREADY_INIT);
        move_to(admin, SupportedTokens { 
            allowed: table::new<TypeInfo, bool>() 
        });
    }

    /// Add/allow Coin<T> (generic, without sending TypeInfo from outside)
    public entry fun add_supported_token<T>(admin: &signer) acquires SupportedTokens {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @relynk, E_NOT_AUTHORIZED);
        assert!(exists<SupportedTokens>(admin_addr), E_NOT_INITIALIZED);

        // Ensure coin T is actually initialized on chain
        assert!(coin::is_coin_initialized<T>(), E_NOT_SUPPORTED);

        let type_info = type_info::type_of<T>();
        let supported_tokens = borrow_global_mut<SupportedTokens>(admin_addr);
        
        // Use upsert pattern - either update existing or add new
        if (table::contains(&supported_tokens.allowed, type_info)) {
            *table::borrow_mut(&mut supported_tokens.allowed, type_info) = true;
        } else {
            table::add(&mut supported_tokens.allowed, type_info, true);
        }
    }

    /// Remove/disable Coin<T> (set to false, don't delete entry)
    public entry fun remove_supported_token<T>(admin: &signer) acquires SupportedTokens {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @relynk, E_NOT_AUTHORIZED);
        assert!(exists<SupportedTokens>(admin_addr), E_NOT_INITIALIZED);

        let type_info = type_info::type_of<T>();
        let supported_tokens = borrow_global_mut<SupportedTokens>(admin_addr);
        
        // Set to false whether it exists or not
        if (table::contains(&supported_tokens.allowed, type_info)) {
            *table::borrow_mut(&mut supported_tokens.allowed, type_info) = false;
        } else {
            table::add(&mut supported_tokens.allowed, type_info, false);
        }
    }

    /// Query: is Coin<T> allowed?
    public fun is_supported<T>(registry_owner: address): bool acquires SupportedTokens {
        if (!exists<SupportedTokens>(registry_owner)) {
            return false
        };
        
        let type_info = type_info::type_of<T>();
        let supported_tokens = borrow_global<SupportedTokens>(registry_owner);
        
        if (table::contains(&supported_tokens.allowed, type_info)) {
            *table::borrow(&supported_tokens.allowed, type_info)
        } else {
            false
        }
    }

    /// Guard: call at the beginning of entry functions that accept assets
    public fun assert_supported<T>(registry_owner: address) acquires SupportedTokens {
        assert!(is_supported<T>(registry_owner), E_NOT_SUPPORTED);
    }

    // Additional helper functions for better usability

    /// Check if the supported tokens registry exists
    public fun registry_exists(registry_owner: address): bool {
        exists<SupportedTokens>(registry_owner)
    }

    #[view]
    /// Check if a specific token type is in the registry (regardless of true/false value)
    public fun token_exists_in_registry<T>(registry_owner: address): bool acquires SupportedTokens {
        if (!exists<SupportedTokens>(registry_owner)) {
            return false
        };
        let type_info = type_info::type_of<T>();
        let supported_tokens = borrow_global<SupportedTokens>(registry_owner);
        table::contains(&supported_tokens.allowed, type_info)
    }

    
}