// #[test_only]
// module relynk::supported_tokens_tests {
//     use std::signer;
//     use aptos_framework::aptos_coin::AptosCoin;
//     use aptos_framework::coin::{Self, MintCapability, BurnCapability};
//     use aptos_framework::account;
//     use relynk::supported_tokens;

//     /// Test coins for testing purposes
//     struct TestCoinA has key {}
//     struct TestCoinB has key {}
//     struct TestCoinC has key {}

//     struct TestCoins has key {
//         mint_cap_a: MintCapability<TestCoinA>,
//         burn_cap_a: BurnCapability<TestCoinA>,
//         mint_cap_b: MintCapability<TestCoinB>,
//         burn_cap_b: BurnCapability<TestCoinB>,
//         mint_cap_c: MintCapability<TestCoinC>,
//         burn_cap_c: BurnCapability<TestCoinC>,
//     }

//     /// Initialize test coins
//     fun init_test_coins(admin: &signer) {
//         let (mint_cap_a, burn_cap_a) = coin::initialize<TestCoinA>(
//             admin,
//             b"Test Coin A",
//             b"TCA",
//             8,
//             false,
//         );
//         let (mint_cap_b, burn_cap_b) = coin::initialize<TestCoinB>(
//             admin,
//             b"Test Coin B", 
//             b"TCB",
//             8,
//             false,
//         );
//         let (mint_cap_c, burn_cap_c) = coin::initialize<TestCoinC>(
//             admin,
//             b"Test Coin C",
//             b"TCC", 
//             8,
//             false,
//         );

//         move_to(admin, TestCoins {
//             mint_cap_a,
//             burn_cap_a,
//             mint_cap_b,
//             burn_cap_b,
//             mint_cap_c,
//             burn_cap_c,
//         });
//     }

//     #[test(admin = @relynk)]
//     public fun test_init_supported_tokens_success(admin: &signer) {
//         // Test successful initialization
//         supported_tokens::init_supported_tokens(admin);
        
//         // Verify registry exists
//         assert!(supported_tokens::registry_exists(signer::address_of(admin)), 1);
        
//         // Verify count is 0 initially
//         assert!(supported_tokens::get_supported_tokens_count(signer::address_of(admin)) == 0, 2);
//     }

//     #[test(admin = @relynk)]
//     #[expected_failure(abort_code = 2, location = relynk::supported_tokens)]
//     public fun test_init_supported_tokens_already_exists(admin: &signer) {
//         // Initialize once
//         supported_tokens::init_supported_tokens(admin);
        
//         // Try to initialize again - should fail
//         supported_tokens::init_supported_tokens(admin);
//     }

//     #[test(non_admin = @0x123)]
//     #[expected_failure(abort_code = 1, location = relynk::supported_tokens)]
//     public fun test_init_supported_tokens_not_authorized(non_admin: &signer) {
//         // Non-admin trying to initialize - should fail
//         supported_tokens::init_supported_tokens(non_admin);
//     }

//     #[test(admin = @relynk)]
//     public fun test_add_supported_token_success(admin: &signer) {
//         // Initialize registry
//         supported_tokens::init_supported_tokens(admin);
        
//         // Initialize test coins
//         init_test_coins(admin);
        
//         // Add supported token
//         supported_tokens::add_supported_token<TestCoinA>(admin);
        
//         // Verify token is supported
//         assert!(supported_tokens::is_supported<TestCoinA>(signer::address_of(admin)), 1);
        
//         // Verify count increased
//         assert!(supported_tokens::get_supported_tokens_count(signer::address_of(admin)) == 1, 2);
//     }

//     #[test(admin = @relynk)]
//     public fun test_add_multiple_supported_tokens(admin: &signer) {
//         // Initialize registry
//         supported_tokens::init_supported_tokens(admin);
        
//         // Initialize test coins
//         init_test_coins(admin);
        
//         // Add multiple tokens
//         supported_tokens::add_supported_token<TestCoinA>(admin);
//         supported_tokens::add_supported_token<TestCoinB>(admin);
//         supported_tokens::add_supported_token<TestCoinC>(admin);
        
//         // Verify all tokens are supported
//         assert!(supported_tokens::is_supported<TestCoinA>(signer::address_of(admin)), 1);
//         assert!(supported_tokens::is_supported<TestCoinB>(signer::address_of(admin)), 2);
//         assert!(supported_tokens::is_supported<TestCoinC>(signer::address_of(admin)), 3);
        
//         // Verify count
//         assert!(supported_tokens::get_supported_tokens_count(signer::address_of(admin)) == 3, 4);
//     }

//     #[test(admin = @relynk)]
//     public fun test_add_same_token_twice(admin: &signer) {
//         // Initialize registry
//         supported_tokens::init_supported_tokens(admin);
        
//         // Initialize test coins
//         init_test_coins(admin);
        
//         // Add token twice
//         supported_tokens::add_supported_token<TestCoinA>(admin);
//         supported_tokens::add_supported_token<TestCoinA>(admin);
        
//         // Should still be supported
//         assert!(supported_tokens::is_supported<TestCoinA>(signer::address_of(admin)), 1);
        
//         // Count should still be 1 (not duplicated)
//         assert!(supported_tokens::get_supported_tokens_count(signer::address_of(admin)) == 1, 2);
//     }

//     #[test(non_admin = @0x123)]
//     #[expected_failure(abort_code = 1, location = relynk::supported_tokens)]
//     public fun test_add_supported_token_not_authorized(non_admin: &signer) {
//         // Create admin account and initialize
//         let admin = account::create_account_for_test(@relynk);
//         supported_tokens::init_supported_tokens(&admin);
//         init_test_coins(&admin);
        
//         // Non-admin trying to add token - should fail
//         supported_tokens::add_supported_token<TestCoinA>(non_admin);
//     }

//     #[test(admin = @relynk)]
//     #[expected_failure(abort_code = 4, location = relynk::supported_tokens)]
//     public fun test_add_supported_token_not_initialized(admin: &signer) {
//         // Initialize test coins but not the registry
//         init_test_coins(admin);
        
//         // Try to add token without initializing registry - should fail
//         supported_tokens::add_supported_token<TestCoinA>(admin);
//     }

//     #[test(admin = @relynk)]
//     public fun test_remove_supported_token_success(admin: &signer) {
//         // Initialize registry and coins
//         supported_tokens::init_supported_tokens(admin);
//         init_test_coins(admin);
        
//         // Add then remove token
//         supported_tokens::add_supported_token<TestCoinA>(admin);
//         assert!(supported_tokens::is_supported<TestCoinA>(signer::address_of(admin)), 1);
        
//         supported_tokens::remove_supported_token<TestCoinA>(admin);
//         assert!(!supported_tokens::is_supported<TestCoinA>(signer::address_of(admin)), 2);
        
//         // Count should still be 1 (entry exists but set to false)
//         assert!(supported_tokens::get_supported_tokens_count(signer::address_of(admin)) == 1, 3);
//     }

//     #[test(admin = @relynk)]
//     public fun test_remove_non_existent_token(admin: &signer) {
//         // Initialize registry and coins
//         supported_tokens::init_supported_tokens(admin);
//         init_test_coins(admin);
        
//         // Remove token that was never added
//         supported_tokens::remove_supported_token<TestCoinA>(admin);
        
//         // Should not be supported
//         assert!(!supported_tokens::is_supported<TestCoinA>(signer::address_of(admin)), 1);
        
//         // Count should be 1 (entry added with false value)
//         assert!(supported_tokens::get_supported_tokens_count(signer::address_of(admin)) == 1, 2);
//     }

//     #[test(admin = @relynk)]
//     public fun test_re_add_removed_token(admin: &signer) {
//         // Initialize registry and coins
//         supported_tokens::init_supported_tokens(admin);
//         init_test_coins(admin);
        
//         // Add, remove, then add again
//         supported_tokens::add_supported_token<TestCoinA>(admin);
//         supported_tokens::remove_supported_token<TestCoinA>(admin);
//         supported_tokens::add_supported_token<TestCoinA>(admin);
        
//         // Should be supported again
//         assert!(supported_tokens::is_supported<TestCoinA>(signer::address_of(admin)), 1);
        
//         // Count should still be 1
//         assert!(supported_tokens::get_supported_tokens_count(signer::address_of(admin)) == 1, 2);
//     }

//     #[test(non_admin = @0x123)]
//     #[expected_failure(abort_code = 1, location = relynk::supported_tokens)]
//     public fun test_remove_supported_token_not_authorized(non_admin: &signer) {
//         // Create admin and initialize
//         let admin = account::create_account_for_test(@relynk);
//         supported_tokens::init_supported_tokens(&admin);
//         init_test_coins(&admin);
        
//         // Non-admin trying to remove token - should fail
//         supported_tokens::remove_supported_token<TestCoinA>(non_admin);
//     }

//     #[test]
//     public fun test_is_supported_no_registry() {
//         // Test query when registry doesn't exist
//         assert!(!supported_tokens::is_supported<TestCoinA>(@0x999), 1);
//     }

//     #[test(admin = @relynk)]
//     public fun test_assert_supported_success(admin: &signer) {
//         // Initialize registry and coins
//         supported_tokens::init_supported_tokens(admin);
//         init_test_coins(admin);
        
//         // Add token and assert - should not abort
//         supported_tokens::add_supported_token<TestCoinA>(admin);
//         supported_tokens::assert_supported<TestCoinA>(signer::address_of(admin));
//     }

//     #[test(admin = @relynk)]
//     #[expected_failure(abort_code = 3, location = relynk::supported_tokens)]
//     public fun test_assert_supported_failure(admin: &signer) {
//         // Initialize registry and coins
//         supported_tokens::init_supported_tokens(admin);
//         init_test_coins(admin);
        
//         // Assert unsupported token - should fail
//         supported_tokens::assert_supported<TestCoinA>(signer::address_of(admin));
//     }

//     #[test(admin = @relynk)]
//     public fun test_registry_exists(admin: &signer) {
//         // Initially doesn't exist
//         assert!(!supported_tokens::registry_exists(signer::address_of(admin)), 1);
        
//         // After initialization, should exist
//         supported_tokens::init_supported_tokens(admin);
//         assert!(supported_tokens::registry_exists(signer::address_of(admin)), 2);
//     }

//     #[test]
//     public fun test_get_supported_tokens_count_no_registry() {
//         // Test count when registry doesn't exist
//         assert!(supported_tokens::get_supported_tokens_count(@0x999) == 0, 1);
//     }

//     #[test(admin = @relynk)]
//     public fun test_complex_workflow(admin: &signer) {
//         // Initialize
//         supported_tokens::init_supported_tokens(admin);
//         init_test_coins(admin);
        
//         let admin_addr = signer::address_of(admin);
        
//         // Add multiple tokens
//         supported_tokens::add_supported_token<TestCoinA>(admin);
//         supported_tokens::add_supported_token<TestCoinB>(admin);
//         assert!(supported_tokens::get_supported_tokens_count(admin_addr) == 2, 1);
        
//         // Remove one token
//         supported_tokens::remove_supported_token<TestCoinA>(admin);
//         assert!(!supported_tokens::is_supported<TestCoinA>(admin_addr), 2);
//         assert!(supported_tokens::is_supported<TestCoinB>(admin_addr), 3);
        
//         // Add third token
//         supported_tokens::add_supported_token<TestCoinC>(admin);
//         assert!(supported_tokens::get_supported_tokens_count(admin_addr) == 3, 4);
        
//         // Re-add first token
//         supported_tokens::add_supported_token<TestCoinA>(admin);
//         assert!(supported_tokens::is_supported<TestCoinA>(admin_addr), 5);
        
//         // Final verification
//         assert!(supported_tokens::is_supported<TestCoinA>(admin_addr), 6);
//         assert!(supported_tokens::is_supported<TestCoinB>(admin_addr), 7);
//         assert!(supported_tokens::is_supported<TestCoinC>(admin_addr), 8);
//         assert!(supported_tokens::get_supported_tokens_count(admin_addr) == 3, 9);
//     }
// }