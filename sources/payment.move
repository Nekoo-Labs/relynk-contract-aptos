module relynk::paymentv1 {
    use std::string::{Self, String};
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::type_info;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_std::table::{Self, Table};
    use relynk::supported_tokens;

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
        link_id: String,
        sender: address,
        amount: u64,
        token: String,
        expires_at: u64,
        timestamp: u64,
    }

    #[event]
    struct TransferClaimed has drop, store {
        link_id: String,
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

    // Initialize escrow account
    public entry fun init(admin: &signer) {
        let who = signer::address_of(admin);
        assert!(who == @relynk, E_NOT_AUTHORIZED);
        
        if (!exists<EscrowCapability>(@relynk)) {
            let (escrow_signer, cap) = account::create_resource_account(admin, b"relynk_escrow_v1");
            // Register for APT and USDC
            coin::register<aptos_framework::aptos_coin::AptosCoin>(&escrow_signer);
            move_to(admin, EscrowCapability { cap });
        }
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

    // 1. Process payment (untuk payment request yang linknya dibuat off-chain)
    // Process payment from payer to recipient directly
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
        link_id: String,
        amount: u64, 
        expires_in_hours: u64
    ) acquires EscrowCapability, TransferLinkStore {
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
        
        // Get the store
        let store = borrow_global_mut<TransferLinkStore<T>>(@relynk);
        assert!(!store.links.contains(link_id), E_LINK_ALREADY_EXISTS);
        
        // Transfer amount to escrow
        coin::transfer<T>(sender, escrow_addr, amount);
        
        let expires_at = timestamp::now_seconds() + expires_in_hours * 3600;
        
        // Create transfer link
        store.links.add(link_id, TransferLink<T> {
            sender: sender_addr,
            amount,
            created_at: timestamp::now_seconds(),
            expires_at,
            is_claimed: false,
        });

        event::emit(TransferLinkCreated {
            link_id,
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
        link_id: String
    ) acquires EscrowCapability, TransferLinkStore {
        let claimer_addr = signer::address_of(claimer);
        
        // Ensure claimer is registered for the token
        if (!coin::is_account_registered<T>(claimer_addr)) {
            coin::register<T>(claimer);
        };
        
        let store = borrow_global_mut<TransferLinkStore<T>>(@relynk);
        assert!(store.links.contains(link_id), E_LINK_NOT_FOUND);
        
        let transfer_link = store.links.borrow_mut(link_id);
        assert!(!transfer_link.is_claimed, E_LINK_ALREADY_CLAIMED);
        assert!(timestamp::now_seconds() <= transfer_link.expires_at, E_LINK_EXPIRED);

        // Get escrow signer and transfer tokens from escrow to claimer
        let cap = borrow_global<EscrowCapability>(@relynk);
        let escrow_signer = account::create_signer_with_capability(&cap.cap);
        
        coin::transfer<T>(&escrow_signer, claimer_addr, transfer_link.amount);
        
        // Mark as claimed
        transfer_link.is_claimed = true;

        event::emit(TransferClaimed {
            link_id,
            sender: transfer_link.sender,
            claimer: claimer_addr,
            amount: transfer_link.amount,
            token: type_info::type_name<T>(),
            timestamp: timestamp::now_seconds(),
        });
    }

    // View function untuk cek info transfer link
    #[view]
    public fun get_transfer_link_info<T>(link_id: String): (address, u64, u64, u64, bool) acquires TransferLinkStore {
        if (!exists<TransferLinkStore<T>>(@relynk)) {
            return (@0x0, 0, 0, 0, false)
        };
        
        let store = borrow_global<TransferLinkStore<T>>(@relynk);
        if (!store.links.contains(link_id)) {
            return (@0x0, 0, 0, 0, false)
        };
        
        let link = store.links.borrow(link_id);
        (link.sender, link.amount, link.created_at, link.expires_at, link.is_claimed)
    }

    #[view]
    public fun is_token_supported<T>(): bool {
        supported_tokens::is_supported<T>(@relynk)
    }
}