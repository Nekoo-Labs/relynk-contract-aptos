module relynk::paymentv1 {
    use std::string::{Self, String};
    use std::signer;
    use std::vector;
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::type_info;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::resource_account;
    use relynk::supported_tokens;

    // Error codes
    const E_TOKEN_NOT_SUPPORTED: u64 = 1;
    const E_INVALID_AMOUNT: u64 = 2; // Amount must be greater than zero
    const E_INSUFFICIENT_BALANCE: u64 = 3; // Not enough balance
    const E_LINK_NOT_FOUND: u64 = 4; // Transfer link does not exist
    const E_LINK_ALREADY_CLAIMED: u64 = 5; // Transfer link already claimed
    const E_LINK_EXPIRED: u64 = 6; // Transfer link expired

    #[event]
    struct PaymentProcessed has drop, store {
        payment_id: String,
        payer: address,
        recipient: address,
        amount: u64,
        token: String,
        metadata: String,
        timestamp: u64,
    }

    #[event]
    struct CreateTransferLink has drop, store {
        link_id: String,
        sender: address,
        amount: u64,
        token: String,
        metadata: String,
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

    struct EscrowCapability has key {
        signer_cap: account::SignerCapability,
    }

    // Transfer link structure
    struct TransferLink<phantom TokenType> has key {
        sender: address,
        amount: u64,
        metadata: String,
        created_at: u64,
        expires_at: u64,
        is_claimed: bool,
        escrow_addr: address,
    }

    // Global Storage for all transfer links
    struct TransferLinkRegistry has key {
        links: vector<String>, // Store all link IDs
    }

    // struct UserTransferLinks has key {
    //     active_links: vector<String>,
    // }

    fun init_module(deployer: &signer) {
        let (resource_signer, signer_cap) = account::create_resource_account(deployer, b"relynk_escrow_v1");
        let escrow_addr = signer::address_of(&resource_signer);

        move_to(deployer, TransferLinkRegistry {
            links: vector::empty<String>(),
        });

        coin::register<aptos_framework::aptos_coin::AptosCoin>(&resource_signer);
    }

    // Payment Processing
    public entry fun payment_process<TokenType>(payer: &signer, recipient: address, amount: u64, payment_id: String, metadata: String) {
        let payer_addr = signer::address_of(payer);

        // Validate inputs
        assert!(amount > 0, E_INVALID_AMOUNT);

        supported_tokens::assert_supported<TokenType>(@relynk);

        let balance = coin::balance<TokenType>(payer_addr);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);

        coin::transfer<TokenType>(payer, recipient, amount);

        let token_name = get_token_name<TokenType>();

        event::emit(PaymentProcessed {
            payment_id,
            payer: payer_addr,
            recipient,
            amount,
            token: token_name,
            metadata,
            timestamp: timestamp::now_seconds(),
        });
    }

    public entry fun create_transfer_link<TokenType>(sender: &signer, amount: u64, link_id: String, metadata: String, expires_in_hours: u64) acquires EscrowCapability {
        let sender_addr = signer::address_of(sender);

        // Validate inputs
        assert!(amount > 0, E_INVALID_AMOUNT);
        // Check token support
        supported_tokens::assert_supported<TokenType>(@relynk);

        let balance = coin::balance<TokenType>(sender_addr);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);

        // Get escrow signer
        let escrow_cap = borrow_global<EscrowCapability>(@relynk);
        let escrow_signer = account::create_signer_with_capability(&escrow_cap.signer_cap);
        let escrow_addr = signer::address_of(&escrow_signer);

        // Transfer tokens to escrow (relynk)
        coin::transfer<TokenType>(sender, escrow_addr, amount);

        // Store transfer link data
        let expires_at = timestamp::now_seconds() + (expires_in_hours * 3600);
        move_to(sender, TransferLink<TokenType> {
            sender: sender_addr,
            amount,
            metadata,
            created_at: timestamp::now_seconds(),
            expires_at,
            is_claimed: false,
            escrow_addr,
        });

        event::emit(CreateTransferLink {
            link_id,
            sender: sender_addr,
            amount,
            token: get_token_name<TokenType>(),
            metadata,
            timestamp: timestamp::now_seconds(),
        });
    }

    // Claim Transfer Link
    public entry fun claim_transfer_link<TokenType>(claimer: &signer, sender_addr: address, link_id: String) acquires EscrowCapability, TransferLink {
        let claimer_addr = signer::address_of(claimer);

        // Get the transfer link
        assert!(exists<TransferLink<TokenType>>(sender_addr), E_LINK_NOT_FOUND);
        let transfer_link = borrow_global_mut<TransferLink<TokenType>>(sender_addr);

        // Validate claim
        assert!(!transfer_link.is_claimed, E_LINK_ALREADY_CLAIMED);
        assert!(timestamp::now_seconds() <= transfer_link.expires_at, E_LINK_EXPIRED);

        // Get escrow signer and transfer
        let escrow_cap = borrow_global<EscrowCapability>(@relynk);
        let escrow_signer = account::create_signer_with_capability(&escrow_cap.signer_cap);

        // Transfer the tokens from escrow (relynk) to the claimer
        coin::transfer<TokenType>(&escrow_signer, claimer_addr, transfer_link.amount);

        // Mark as claimed
        transfer_link.is_claimed = true;

        event::emit(TransferClaimed {
            link_id,
            sender: transfer_link.sender,
            claimer: claimer_addr,
            amount: transfer_link.amount,
            token: get_token_name<TokenType>(),
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Query function to get transfer link info
    #[view]
    public fun get_transfer_link_info<TokenType>(sender:address): (u64, bool, u64) acquires TransferLink {
        if (exists<TransferLink<TokenType>>(sender)) {
            let link = borrow_global<TransferLink<TokenType>>(sender);
            (link.amount, link.is_claimed, link.expires_at)
        } else {
            (0, false, 0)
        }
    }

    /// Helper function to get token name from TypeInfo
    fun get_token_name<TokenType>(): String {
        type_info::type_name<TokenType>()
    }

    #[view]
    /// Query function to check if a token is supported
    public fun is_token_supported<TokenType>(): bool {
        supported_tokens::is_supported<TokenType>(@relynk)
    }

    // /// Batch payment function (multiple recipients)
    // public entry fun batch_payment<TokenType>(
    //     payer: &signer,
    //     recipients: vector<address>,
    //     amounts: vector<u64>,
    //     _payment_id: String,
    //     metadata: String
    // ) {
    //     let payer_addr = signer::address_of(payer);

    //     // Validate token support
    //     supported_tokens::assert_supported<TokenType>(@relynk);

    //     // Validate input lengths match
    //     assert!(recipients.length() == amounts.length(), E_INVALID_AMOUNT);

    //     let recipients_len = recipients.length();
    //     let total_amount = calculate_total_amount(&amounts);

    //     // Check total balance
    //     let balance = coin::balance<TokenType>(payer_addr);
    //     assert!(balance >= total_amount, E_INSUFFICIENT_BALANCE);

    //     // Process payments
    //     let i = 0;
    //     while (i < recipients_len) {
    //         let recipient = recipients[i];
    //         let amount = amounts[i];

    //         coin::transfer<TokenType>(payer, recipient, amount);

    //         // Emit individual payment event
    //         event::emit(PaymentProcessed {
    //             payment_id: string::utf8(b"batch_"),
    //             payer: payer_addr,
    //             recipient,
    //             amount,
    //             token: get_token_name<TokenType>(),
    //             metadata,
    //             timestamp: timestamp::now_seconds(),
    //         });

    //         i += 1;
    //     };
    // }

    // /// Helper function to calculate total amount from vector
    // fun calculate_total_amount(amounts: &vector<u64>): u64 {
    //     let len = amounts.length();
    //     let total = 0;
    //     let i = 0;

    //     while (i < len) {
    //         let amount = amounts[i];
    //         assert!(amount > 0, E_INVALID_AMOUNT);
    //         total += amount;
    //         i += 1;
    //     };

    //     total
    // }
}