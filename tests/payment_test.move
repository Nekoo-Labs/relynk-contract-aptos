#[test_only]
module relynk::payment_tests {
    use std::signer;
    use std::string;
    use aptos_framework::coin;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use relynk::paymentv1;
    use relynk::supported_tokens;

    // Mock USDC for testing
    struct MockUSDC {}

    struct MockUSDCCapabilities has key {
        burn_cap: coin::BurnCapability<MockUSDC>,
        freeze_cap: coin::FreezeCapability<MockUSDC>,
        mint_cap: coin::MintCapability<MockUSDC>,
    }

    // Initialize MockUSDC for testing
    fun init_mock_usdc(account: &signer) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<MockUSDC>(
            account,
            string::utf8(b"Mock USDC"),
            string::utf8(b"mUSDC"),
            6,
            false,
        );
        
        move_to(account, MockUSDCCapabilities {
            burn_cap,
            freeze_cap,
            mint_cap,
        });
    }

    // Helper to mint MockUSDC
    fun mint_mock_usdc(account: &signer, amount: u64): coin::Coin<MockUSDC> acquires MockUSDCCapabilities {
        let caps = borrow_global<MockUSDCCapabilities>(signer::address_of(account));
        coin::mint<MockUSDC>(amount, &caps.mint_cap)
    }

    #[test(aptos_framework = @0x1, relynk = @relynk, sender = @0x100, recipient = @0x200, claimer = @0x300)]
    public fun test_init_and_setup(
        aptos_framework: &signer,
        relynk: &signer,
        sender: &signer,
        recipient: &signer,
        claimer: &signer
    ) {
        // Initialize timestamp
        timestamp::set_time_has_started_for_testing(aptos_framework);

        // Initialize AptosCoin
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        // Initialize accounts
        account::create_account_for_test(signer::address_of(relynk));
        account::create_account_for_test(signer::address_of(sender));
        account::create_account_for_test(signer::address_of(recipient));
        account::create_account_for_test(signer::address_of(claimer));

        // Initialize MockUSDC
        init_mock_usdc(relynk);

        // Initialize supported tokens
        supported_tokens::init_supported_tokens(relynk);
        supported_tokens::add_supported_token<AptosCoin>(relynk);
        supported_tokens::add_supported_token<MockUSDC>(relynk);

        // Initialize payment system
        paymentv1::init(relynk);
        paymentv1::ensure_store<AptosCoin>(relynk);
        paymentv1::ensure_store<MockUSDC>(relynk);

        // Verify tokens are supported
        assert!(paymentv1::is_token_supported<AptosCoin>(), 1);
        assert!(paymentv1::is_token_supported<MockUSDC>(), 2);

        // Clean up
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, relynk = @relynk, payer = @0x100, recipient = @0x200)]
    public fun test_process_payment_apt(
        aptos_framework: &signer,
        relynk: &signer,
        payer: &signer,
        recipient: &signer
    ) {
        // Setup
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        account::create_account_for_test(signer::address_of(relynk));
        account::create_account_for_test(signer::address_of(payer));
        account::create_account_for_test(signer::address_of(recipient));

        supported_tokens::init_supported_tokens(relynk);
        supported_tokens::add_supported_token<AptosCoin>(relynk);
        
        paymentv1::init(relynk);
        paymentv1::ensure_store<AptosCoin>(relynk);

        // Register accounts
        coin::register<AptosCoin>(payer);
        coin::register<AptosCoin>(recipient);

        // Mint some APT for payer
        let coins = coin::mint<AptosCoin>(1000000000, &mint_cap); // 10 APT
        coin::deposit<AptosCoin>(signer::address_of(payer), coins);

        // Test payment
        let amount = 500000000; // 5 APT
        paymentv1::process_payment<AptosCoin>(
            payer, 
            signer::address_of(recipient), 
            amount, 
            string::utf8(b"test_payment_001")
        );

        // Verify balances
        assert!(coin::balance<AptosCoin>(signer::address_of(payer)) == 500000000, 3); // 5 APT left
        assert!(coin::balance<AptosCoin>(signer::address_of(recipient)) == 500000000, 4); // 5 APT received

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, relynk = @relynk, payer = @0x100, recipient = @0x200)]
    public fun test_process_payment_mock_usdc(
        aptos_framework: &signer,
        relynk: &signer,
        payer: &signer,
        recipient: &signer
    ) acquires MockUSDCCapabilities {
        // Setup
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        account::create_account_for_test(signer::address_of(relynk));
        account::create_account_for_test(signer::address_of(payer));
        account::create_account_for_test(signer::address_of(recipient));

        init_mock_usdc(relynk);
        supported_tokens::init_supported_tokens(relynk);
        supported_tokens::add_supported_token<MockUSDC>(relynk);
        
        paymentv1::init(relynk);
        paymentv1::ensure_store<MockUSDC>(relynk);

        // Register accounts for MockUSDC
        coin::register<MockUSDC>(payer);
        coin::register<MockUSDC>(recipient);

        // Mint some MockUSDC for payer
        let coins = mint_mock_usdc(relynk, 100000000); // 100 USDC (6 decimals)
        coin::deposit<MockUSDC>(signer::address_of(payer), coins);

        // Test payment
        let amount = 50000000; // 50 USDC
        paymentv1::process_payment<MockUSDC>(
            payer, 
            signer::address_of(recipient), 
            amount, 
            string::utf8(b"test_usdc_payment_001")
        );

        // Verify balances
        assert!(coin::balance<MockUSDC>(signer::address_of(payer)) == 50000000, 5); // 50 USDC left
        assert!(coin::balance<MockUSDC>(signer::address_of(recipient)) == 50000000, 6); // 50 USDC received

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, relynk = @relynk, sender = @0x100, claimer = @0x200)]
    public fun test_transfer_link_flow_apt(
        aptos_framework: &signer,
        relynk: &signer,
        sender: &signer,
        claimer: &signer
    ) {
        // Setup
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        account::create_account_for_test(signer::address_of(relynk));
        account::create_account_for_test(signer::address_of(sender));
        account::create_account_for_test(signer::address_of(claimer));

        supported_tokens::init_supported_tokens(relynk);
        supported_tokens::add_supported_token<AptosCoin>(relynk);
        
        paymentv1::init(relynk);
        paymentv1::ensure_store<AptosCoin>(relynk);

        // Register accounts
        coin::register<AptosCoin>(sender);
        coin::register<AptosCoin>(claimer);

        // Mint some APT for sender
        let coins = coin::mint<AptosCoin>(1000000000, &mint_cap); // 10 APT
        coin::deposit<AptosCoin>(signer::address_of(sender), coins);

        let initial_sender_balance = coin::balance<AptosCoin>(signer::address_of(sender));

        // Create transfer link
        let amount = 300000000; // 3 APT
        let link_id = string::utf8(b"transfer_link_001");
        paymentv1::create_transfer_with_link<AptosCoin>(
            sender, 
            link_id, 
            amount, 
            24 // expires in 24 hours
        );

        // Verify sender balance decreased
        assert!(coin::balance<AptosCoin>(signer::address_of(sender)) == initial_sender_balance - amount, 7);

        // Verify link info
        let (link_sender, link_amount, created_at, expires_at, is_claimed) = 
            paymentv1::get_transfer_link_info<AptosCoin>(link_id);
        
        assert!(link_sender == signer::address_of(sender), 8);
        assert!(link_amount == amount, 9);
        assert!(!is_claimed, 10);
        assert!(expires_at > created_at, 11);

        // Claim the transfer
        let initial_claimer_balance = coin::balance<AptosCoin>(signer::address_of(claimer));
        paymentv1::claim_transfer<AptosCoin>(claimer, link_id);

        // Verify claimer received the amount
        assert!(coin::balance<AptosCoin>(signer::address_of(claimer)) == initial_claimer_balance + amount, 12);

        // Verify link is now claimed
        let (_, _, _, _, is_claimed_after) = paymentv1::get_transfer_link_info<AptosCoin>(link_id);
        assert!(is_claimed_after, 13);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, relynk = @relynk, sender = @0x100, claimer = @0x200)]
    public fun test_transfer_link_flow_mock_usdc(
        aptos_framework: &signer,
        relynk: &signer,
        sender: &signer,
        claimer: &signer
    ) acquires MockUSDCCapabilities {
        // Setup
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        account::create_account_for_test(signer::address_of(relynk));
        account::create_account_for_test(signer::address_of(sender));
        account::create_account_for_test(signer::address_of(claimer));

        init_mock_usdc(relynk);
        supported_tokens::init_supported_tokens(relynk);
        supported_tokens::add_supported_token<MockUSDC>(relynk);
        
        paymentv1::init(relynk);
        paymentv1::ensure_store<MockUSDC>(relynk);

        // Register accounts
        coin::register<MockUSDC>(sender);
        coin::register<MockUSDC>(claimer);

        // Mint some MockUSDC for sender
        let coins = mint_mock_usdc(relynk, 500000000); // 500 USDC
        coin::deposit<MockUSDC>(signer::address_of(sender), coins);

        let initial_sender_balance = coin::balance<MockUSDC>(signer::address_of(sender));

        // Create transfer link
        let amount = 100000000; // 100 USDC
        let link_id = string::utf8(b"usdc_transfer_link_001");
        paymentv1::create_transfer_with_link<MockUSDC>(
            sender, 
            link_id, 
            amount, 
            48 // expires in 48 hours
        );

        // Verify sender balance decreased
        assert!(coin::balance<MockUSDC>(signer::address_of(sender)) == initial_sender_balance - amount, 14);

        // Claim the transfer
        let initial_claimer_balance = coin::balance<MockUSDC>(signer::address_of(claimer));
        paymentv1::claim_transfer<MockUSDC>(claimer, link_id);

        // Verify claimer received the amount
        assert!(coin::balance<MockUSDC>(signer::address_of(claimer)) == initial_claimer_balance + amount, 15);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, relynk = @relynk, sender = @0x100, claimer = @0x200)]
    #[expected_failure(abort_code = 8, location = relynk::paymentv1)] // E_LINK_ALREADY_EXISTS
    public fun test_create_duplicate_transfer_link(
        aptos_framework: &signer,
        relynk: &signer,
        sender: &signer,
        claimer: &signer
    ) {
        // Setup
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        account::create_account_for_test(signer::address_of(relynk));
        account::create_account_for_test(signer::address_of(sender));

        supported_tokens::init_supported_tokens(relynk);
        supported_tokens::add_supported_token<AptosCoin>(relynk);
        
        paymentv1::init(relynk);
        paymentv1::ensure_store<AptosCoin>(relynk);

        coin::register<AptosCoin>(sender);

        // Mint some APT for sender
        let coins = coin::mint<AptosCoin>(1000000000, &mint_cap);
        coin::deposit<AptosCoin>(signer::address_of(sender), coins);

        let link_id = string::utf8(b"duplicate_link");
        let amount = 100000000; // 1 APT

        // Create first link
        paymentv1::create_transfer_with_link<AptosCoin>(sender, link_id, amount, 24);

        // Try to create duplicate link - should fail
        paymentv1::create_transfer_with_link<AptosCoin>(sender, link_id, amount, 24);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, relynk = @relynk, sender = @0x100, claimer = @0x200)]
    #[expected_failure(abort_code = 5, location = relynk::paymentv1)] // E_LINK_ALREADY_CLAIMED
    public fun test_claim_already_claimed_link(
        aptos_framework: &signer,
        relynk: &signer,
        sender: &signer,
        claimer: &signer
    ) {
        // Setup
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        account::create_account_for_test(signer::address_of(relynk));
        account::create_account_for_test(signer::address_of(sender));
        account::create_account_for_test(signer::address_of(claimer));

        supported_tokens::init_supported_tokens(relynk);
        supported_tokens::add_supported_token<AptosCoin>(relynk);
        
        paymentv1::init(relynk);
        paymentv1::ensure_store<AptosCoin>(relynk);

        coin::register<AptosCoin>(sender);
        coin::register<AptosCoin>(claimer);

        // Mint some APT for sender
        let coins = coin::mint<AptosCoin>(1000000000, &mint_cap);
        coin::deposit<AptosCoin>(signer::address_of(sender), coins);

        let link_id = string::utf8(b"claim_test_link");
        let amount = 100000000; // 1 APT

        // Create and claim link
        paymentv1::create_transfer_with_link<AptosCoin>(sender, link_id, amount, 24);
        paymentv1::claim_transfer<AptosCoin>(claimer, link_id);

        // Try to claim again - should fail
        paymentv1::claim_transfer<AptosCoin>(claimer, link_id);

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, relynk = @relynk, sender = @0x100, claimer = @0x200)]
    #[expected_failure(abort_code = 4, location = relynk::paymentv1)] // E_LINK_NOT_FOUND
    public fun test_claim_nonexistent_link(
        aptos_framework: &signer,
        relynk: &signer,
        sender: &signer,
        claimer: &signer
    ) {
        // Setup
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        account::create_account_for_test(signer::address_of(relynk));
        account::create_account_for_test(signer::address_of(claimer));

        supported_tokens::init_supported_tokens(relynk);
        supported_tokens::add_supported_token<AptosCoin>(relynk);
        
        paymentv1::init(relynk);
        paymentv1::ensure_store<AptosCoin>(relynk);

        coin::register<AptosCoin>(claimer);

        // Try to claim non-existent link - should fail
        paymentv1::claim_transfer<AptosCoin>(claimer, string::utf8(b"nonexistent_link"));

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }

    #[test(aptos_framework = @0x1, relynk = @relynk, payer = @0x100, recipient = @0x200)]
    #[expected_failure(abort_code = 3, location = relynk::paymentv1)] // E_INSUFFICIENT_BALANCE
    public fun test_process_payment_insufficient_balance(
        aptos_framework: &signer,
        relynk: &signer,
        payer: &signer,
        recipient: &signer
    ) {
        // Setup
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(aptos_framework);
        
        account::create_account_for_test(signer::address_of(relynk));
        account::create_account_for_test(signer::address_of(payer));
        account::create_account_for_test(signer::address_of(recipient));

        supported_tokens::init_supported_tokens(relynk);
        supported_tokens::add_supported_token<AptosCoin>(relynk);
        
        paymentv1::init(relynk);
        paymentv1::ensure_store<AptosCoin>(relynk);

        coin::register<AptosCoin>(payer);
        coin::register<AptosCoin>(recipient);

        // Try to pay more than available balance - should fail
        paymentv1::process_payment<AptosCoin>(
            payer, 
            signer::address_of(recipient), 
            1000000000, // 10 APT but payer has 0
            string::utf8(b"insufficient_balance_test")
        );

        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
    }
}