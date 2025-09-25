module relynk::paymentv1 {
    use std::string::{Self, String};
    use std::signer;
    use std::vector;
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::type_info;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_std::table::{Self, Table};
    use std::hash;
    use relynk::supported_tokens;
    use relynk::mock_usdc::MockUSDC;

    // Error codes
    const E_TOKEN_NOT_SUPPORTED: u64 = 1;
    const E_INVALID_AMOUNT: u64 = 2;
    const E_INSUFFICIENT_BALANCE: u64 = 3;
    const E_LINK_NOT_FOUND: u64 = 4;
    const E_LINK_ALREADY_CLAIMED: u64 = 5;
    const E_LINK_EXPIRED: u64 = 6;
    const E_NOT_AUTHORIZED: u64 = 7;
    const E_LINK_ALREADY_EXISTS: u64 = 8;

    // Events
    #[event]
    struct PaymentProcessed has drop, store {
        payment_id: String,
        payer: address,
        recipient: address,
        amount: u64,
        token: String,
        timestamp: u64,
    }

    #[event]
    struct TransferLinkCreated has drop, store {
        link_hash: String,
        sender: address,
        amount: u64,
        token: String,
        expires_at: u64,
        timestamp: u64,
    }

    #[event]
    struct TransferClaimed has drop, store {
        link_hash: String,
        sender: address,
        claimer: address,
        amount: u64,
        token: String,
        timestamp: u64,
    }

    // Escrow capability for resource account
    struct EscrowCapability has key {
        cap: account::SignerCapability
    }

    struct LinkCounter has key {
        count: u64,
    }

    // Store for transfer links
    struct TransferLinkStore<phantom T> has key {
        links: Table<String, TransferLink<T>>,
    }

    // Transfer link structure
    struct TransferLink<phantom T> has store {
        sender: address,
        amount: u64,
        created_at: u64,
        expires_at: u64,
        is_claimed: bool,
    }

    fun generate_secret_id(sender: address, counter: u64): String {
        let timestamp = timestamp::now_seconds();
        let data = vector::empty<u8>();

        let timestamp_bytes = vector::empty<u8>();
        let temp_timestamp = timestamp;
        while (temp_timestamp > 0) {
            timestamp_bytes.push_back((temp_timestamp % 256) as u8);
            temp_timestamp /= 256;
        };
        data.append(timestamp_bytes);

        let sender_bytes = std::bcs::to_bytes(&sender);
        data.append(sender_bytes);

        let counter_bytes = vector::empty<u8>();
        let temp_counter = counter;
        while (temp_counter > 0) {
            counter_bytes.push_back((temp_counter % 256) as u8);
            temp_counter /= 256;
        };
        data.append(counter_bytes);
        
        let hash_bytes = hash::sha3_256(data);

        let hex_chars = b"0123456789abcdef";
        let hex_string = vector::empty<u8>();
        let i = 0;
        while (i < hash_bytes.length()) {
            let byte = hash_bytes[i];
            hex_string.push_back(hex_chars[(byte >> 4) as u64]);
            hex_string.push_back(hex_chars[(byte & 0x0f) as u64]);
            i += 1;
        };

        string::utf8(hex_string)
    }

    // Hash secret for storage key
    fun hash_secret(secret: &String): String {
        let secret_bytes = secret.bytes();
        let hash_bytes = hash::sha3_256(*secret_bytes);

        let hex_chars = b"0123456789abcdef";
        let hex_string = vector::empty<u8>();
        let i = 0;
        while (i < hash_bytes.length()) {
            let byte = hash_bytes[i];
            hex_string.push_back(hex_chars[(byte >> 4) as u64]);
            hex_string.push_back(hex_chars[(byte & 0x0f) as u64]);
            i += 1;
        };
        string::utf8(hex_string)
    }

    // Initialize escrow account
    fun init_module(admin: &signer) {
        let (escrow_signer, cap) = account::create_resource_account(admin, b"relynk_escrow_v1");
        
        // Register tokens for escrow
        coin::register<aptos_framework::aptos_coin::AptosCoin>(&escrow_signer);
        coin::register<MockUSDC>(&escrow_signer);

        move_to(admin, EscrowCapability { cap });
        move_to(admin, LinkCounter { count: 0 });

        // auto add mock USDC as supported token
        supported_tokens::add_supported_token<MockUSDC>(admin);
        supported_tokens::add_supported_token<AptosCoin>(admin);
    }

    // Ensure store exists for a token type
    public entry fun ensure_store<T: store>(admin: &signer) {
        let who = signer::address_of(admin);
        assert!(who == @relynk, E_NOT_AUTHORIZED);
        
        if (!exists<TransferLinkStore<T>>(@relynk)) {
            move_to(admin, TransferLinkStore<T> { 
                links: table::new<String, TransferLink<T>>() 
            });
        }
    }

    // Process payment from link
    public entry fun process_payment<T: store>(
        payer: &signer, 
        recipient: address, 
        amount: u64, 
        payment_id: String
    ) {
        let payer_addr = signer::address_of(payer);

        // Validate inputs
        assert!(amount > 0, E_INVALID_AMOUNT);
        supported_tokens::assert_supported<T>(@relynk);

        // Check payer balance
        let balance = coin::balance<T>(payer_addr);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);

        // Ensure both accounts are registered for the token
        if (!coin::is_account_registered<T>(payer_addr)) {
            coin::register<T>(payer);
        };

        // Direct transfer from payer to recipient
        coin::transfer<T>(payer, recipient, amount);

        // Emit event
        event::emit(PaymentProcessed {
            payment_id,
            payer: payer_addr,
            recipient,
            amount,
            token: type_info::type_name<T>(),
            timestamp: timestamp::now_seconds(),
        });
    }

    // 2. Create transfer with link (sender creates link, money held in escrow)
    public entry fun create_transfer_with_link<T: store>(
        sender: &signer,
        amount: u64, 
        expires_in_hours: u64
    ) acquires EscrowCapability, TransferLinkStore, LinkCounter {
        assert!(amount > 0, E_INVALID_AMOUNT);
        supported_tokens::assert_supported<T>(@relynk);
        
        let sender_addr = signer::address_of(sender);
        
        // Check if sender has enough balance
        let balance = coin::balance<T>(sender_addr);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);
        
        // Ensure sender is registered for the token
        if (!coin::is_account_registered<T>(sender_addr)) {
            coin::register<T>(sender);
        };
        
        // Get escrow signer
        let cap = borrow_global<EscrowCapability>(@relynk);
        let escrow_signer = account::create_signer_with_capability(&cap.cap);
        let escrow_addr = signer::address_of(&escrow_signer);
        
        // Ensure escrow is registered for this token
        if (!coin::is_account_registered<T>(escrow_addr)) {
            coin::register<T>(&escrow_signer);
        };

        // Auto create store if not exists
        if (!exists<TransferLinkStore<T>>(@relynk)) {
            let admin_signer = account::create_signer_with_capability(&cap.cap);
            move_to(&admin_signer, TransferLinkStore<T> { 
                links: table::new<String, TransferLink<T>>() 
            });
        };

        // Generate unique claim ID
        let counter = borrow_global_mut<LinkCounter>(@relynk);
        counter.count += 1;
        let secret_claim_id = generate_secret_id(sender_addr, counter.count);

        let link_hash = hash_secret(&secret_claim_id);
        
        // Get the store
        let store = borrow_global_mut<TransferLinkStore<T>>(@relynk);
        
        // Transfer amount to escrow
        coin::transfer<T>(sender, escrow_addr, amount);
        
        let expires_at = timestamp::now_seconds() + expires_in_hours * 3600;
        
        // Create transfer link
        store.links.add(link_hash, TransferLink<T> {
            sender: sender_addr,
            amount,
            created_at: timestamp::now_seconds(),
            expires_at,
            is_claimed: false,
        });

        event::emit(TransferLinkCreated {
            link_hash,
            sender: sender_addr,
            amount,
            token: type_info::type_name<T>(),
            expires_at,
            timestamp: timestamp::now_seconds(),
        });
    }

    // 3. Claim transfer (recipient claims money from link)
    public entry fun claim_transfer<T: store>(
        claimer: &signer, 
        secret_claim_id: String
    ) acquires EscrowCapability, TransferLinkStore {
        let claimer_addr = signer::address_of(claimer);
        
        // Ensure claimer is registered for the token
        if (!coin::is_account_registered<T>(claimer_addr)) {
            coin::register<T>(claimer);
        };

        let link_hash = hash_secret(&secret_claim_id);
        
        let store = borrow_global_mut<TransferLinkStore<T>>(@relynk);
        assert!(store.links.contains(link_hash), E_LINK_NOT_FOUND);

        let transfer_link = store.links.borrow_mut(link_hash);
        assert!(!transfer_link.is_claimed, E_LINK_ALREADY_CLAIMED);
        assert!(timestamp::now_seconds() <= transfer_link.expires_at, E_LINK_EXPIRED);

        // Get escrow signer and transfer tokens from escrow to claimer
        let cap = borrow_global<EscrowCapability>(@relynk);
        let escrow_signer = account::create_signer_with_capability(&cap.cap);
        
        coin::transfer<T>(&escrow_signer, claimer_addr, transfer_link.amount);
        
        // Mark as claimed
        transfer_link.is_claimed = true;

        event::emit(TransferClaimed {
            link_hash,
            sender: transfer_link.sender,
            claimer: claimer_addr,
            amount: transfer_link.amount,
            token: type_info::type_name<T>(),
            timestamp: timestamp::now_seconds(),
        });
    }

    public fun simulate_create_transfer<T: store>(sender_addr: address, amount: u64, expires_in_hours: u64): String acquires LinkCounter {
        let counter = if (exists<LinkCounter>(@relynk)) {
            borrow_global<LinkCounter>(@relynk).count + 1
        } else {
            1
        };

        generate_secret_id(sender_addr, counter)
    }

    // View function untuk cek info transfer link
    #[view]
    public fun get_transfer_link_info<T>(secret_claim_id: String): (address, u64, u64, u64, bool) acquires TransferLinkStore {
        if (!exists<TransferLinkStore<T>>(@relynk)) {
            return (@0x0, 0, 0, 0, false)
        };
        
        let link_hash = hash_secret(&secret_claim_id);
        let store = borrow_global<TransferLinkStore<T>>(@relynk);
        if (!store.links.contains(link_hash)) {
            return (@0x0, 0, 0, 0, false)
        };

        let link = store.links.borrow(link_hash);
        (link.sender, link.amount, link.created_at, link.expires_at, link.is_claimed)
    }

    // current counter (for debugging)
    #[view]
    public fun get_current_counter(): u64 acquires LinkCounter {
        if (!exists<LinkCounter>(@relynk)) return 0;
        borrow_global<LinkCounter>(@relynk).count
    }

    #[view]
    public fun is_token_supported<T>(): bool {
        supported_tokens::is_supported<T>(@relynk)
    }

    #[view]
    public fun get_hash_from_secret(secret: String): String {
        hash_secret(&secret)
    }
}