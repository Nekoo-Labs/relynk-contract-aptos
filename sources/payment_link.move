// module relynk::PaymentLinks {
//     use std::string::{Self, String};
//     use std::signer;
//     use std::vector;
//     use aptos_framework::coin::{Self, Coin};
//     use aptos_framework::aptos_coin::AptosCoin;
//     use aptos_framework::event::{Self, EventHandle};
//     use aptos_framework::account;
//     use aptos_framework::timestamp;

//     /// Error codes
//     const E_NOT_CREATOR: u64 = 1;
//     const E_PAYMENT_LINK_NOT_FOUND: u64 = 2;
//     const E_INSUFFICIENT_PAYMENT: u64 = 3;
//     const E_PAYMENT_LINK_INACTIVE: u64 = 4;
//     const E_ALREADY_PAID: u64 = 5;

//     /// Payment link status
//     const PAYMENT_STATUS_ACTIVE: u8 = 1;
//     const PAYMENT_STATUS_INACTIVE: u8 = 2;
//     const PAYMENT_STATUS_COMPLETED: u8 = 3;

//     /// Payment link structure
//     struct PaymentLink has key, store {
//         id: String,
//         creator: address,
//         title: String,
//         description: String,
//         amount: u64,
//         currency: String, // "APT", "USDC", etc.
//         status: u8,
//         created_at: u64,
//         total_payments: u64,
//         is_recurring: bool,
//         max_uses: u64, // 0 for unlimited
//         current_uses: u64,
//     }

//     /// Payment record
//     struct Payment has store {
//         payer: address,
//         amount: u64,
//         timestamp: u64,
//         transaction_hash: String,
//     }

//     /// Creator's payment links store
//     struct CreatorPaymentLinks has key {
//         links: vector<PaymentLink>,
//         payments: vector<Payment>,
//         total_earnings: u64,
//         payment_events: EventHandle<PaymentEvent>,
//         link_creation_events: EventHandle<LinkCreationEvent>,
//     }

//     /// Events
//     struct PaymentEvent has drop, store {
//         link_id: String,
//         payer: address,
//         creator: address,
//         amount: u64,
//         timestamp: u64,
//     }

//     struct LinkCreationEvent has drop, store {
//         link_id: String,
//         creator: address,
//         title: String,
//         amount: u64,
//         timestamp: u64,
//     }

//     /// Initialize creator's payment links store
//     public entry fun initialize_creator(creator: &signer) {
//         let creator_addr = signer::address_of(creator);
//         if (!exists<CreatorPaymentLinks>(creator_addr)) {
//             move_to(creator, CreatorPaymentLinks {
//                 links: vector::empty<PaymentLink>(),
//                 payments: vector::empty<Payment>(),
//                 total_earnings: 0,
//                 payment_events: account::new_event_handle<PaymentEvent>(creator),
//                 link_creation_events: account::new_event_handle<LinkCreationEvent>(creator),
//             });
//         }
//     }

//     /// Create a new payment link
//     public entry fun create_payment_link(
//         creator: &signer,
//         id: String,
//         title: String,
//         description: String,
//         amount: u64,
//         currency: String,
//         is_recurring: bool,
//         max_uses: u64,
//     ) acquires CreatorPaymentLinks {
//         let creator_addr = signer::address_of(creator);

//         // Initialize if not exists
//         if (!exists<CreatorPaymentLinks>(creator_addr)) {
//             initialize_creator(creator);
//         };

//         let creator_links = borrow_global_mut<CreatorPaymentLinks>(creator_addr);

//         let payment_link = PaymentLink {
//             id: id,
//             creator: creator_addr,
//             title: title,
//             description: description,
//             amount: amount,
//             currency: currency,
//             status: PAYMENT_STATUS_ACTIVE,
//             created_at: timestamp::now_seconds(),
//             total_payments: 0,
//             is_recurring: is_recurring,
//             max_uses: max_uses,
//             current_uses: 0,
//         };

//         vector::push_back(&mut creator_links.links, payment_link);

//         // Emit link creation event
//         event::emit_event(&mut creator_links.link_creation_events, LinkCreationEvent {
//             link_id: id,
//             creator: creator_addr,
//             title: title,
//             amount: amount,
//             timestamp: timestamp::now_seconds(),
//         });
//     }

//     /// Process payment for a payment link (APT only for MVP)
//     public entry fun process_payment(
//         payer: &signer,
//         creator_addr: address,
//         link_id: String,
//         payment_amount: u64,
//     ) acquires CreatorPaymentLinks {
//         let payer_addr = signer::address_of(payer);
//         let creator_links = borrow_global_mut<CreatorPaymentLinks>(creator_addr);

//         // Find the payment link
//         let (link_found, link_index) = find_payment_link(&creator_links.links, &link_id);
//         assert!(link_found, E_PAYMENT_LINK_NOT_FOUND);

//         let payment_link = vector::borrow_mut(&mut creator_links.links, link_index);

//         // Validate payment link
//         assert!(payment_link.status == PAYMENT_STATUS_ACTIVE, E_PAYMENT_LINK_INACTIVE);
//         assert!(payment_amount >= payment_link.amount, E_INSUFFICIENT_PAYMENT);

//         // Check max uses
//         if (payment_link.max_uses > 0) {
//             assert!(payment_link.current_uses < payment_link.max_uses, E_ALREADY_PAID);
//         };

//         // Transfer payment (APT)
//         let payment_coin = coin::withdraw<AptosCoin>(payer, payment_amount);
//         coin::deposit(creator_addr, payment_coin);

//         // Update payment link
//         payment_link.total_payments = payment_link.total_payments + payment_amount;
//         payment_link.current_uses = payment_link.current_uses + 1;

//         // If max uses reached, mark as completed
//         if (payment_link.max_uses > 0 && payment_link.current_uses >= payment_link.max_uses) {
//             payment_link.status = PAYMENT_STATUS_COMPLETED;
//         };

//         // Record payment
//         let payment_record = Payment {
//             payer: payer_addr,
//             amount: payment_amount,
//             timestamp: timestamp::now_seconds(),
//             transaction_hash: string::utf8(b""), // Will be filled by backend
//         };

//         vector::push_back(&mut creator_links.payments, payment_record);
//         creator_links.total_earnings = creator_links.total_earnings + payment_amount;

//         // Emit payment event
//         event::emit_event(&mut creator_links.payment_events, PaymentEvent {
//             link_id: link_id,
//             payer: payer_addr,
//             creator: creator_addr,
//             amount: payment_amount,
//             timestamp: timestamp::now_seconds(),
//         });
//     }

//     /// Update payment link status
//     public entry fun update_link_status(
//         creator: &signer,
//         link_id: String,
//         new_status: u8,
//     ) acquires CreatorPaymentLinks {
//         let creator_addr = signer::address_of(creator);
//         let creator_links = borrow_global_mut<CreatorPaymentLinks>(creator_addr);

//         let (link_found, link_index) = find_payment_link(&creator_links.links, &link_id);
//         assert!(link_found, E_PAYMENT_LINK_NOT_FOUND);

//         let payment_link = vector::borrow_mut(&mut creator_links.links, link_index);
//         assert!(payment_link.creator == creator_addr, E_NOT_CREATOR);

//         payment_link.status = new_status;
//     }

//     /// Helper function to find payment link by ID
//     fun find_payment_link(links: &vector<PaymentLink>, link_id: &String): (bool, u64) {
//         let i = 0;
//         let len = vector::length(links);

//         while (i < len) {
//             let link = vector::borrow(links, i);
//             if (link.id == *link_id) {
//                 return (true, i)
//             };
//             i = i + 1;
//         };

//         (false, 0)
//     }

//     /// View functions
//     #[view]
//     public fun get_payment_link(creator_addr: address, link_id: String): (String, String, u64, u8, u64, u64) acquires CreatorPaymentLinks {
//         let creator_links = borrow_global<CreatorPaymentLinks>(creator_addr);
//         let (link_found, link_index) = find_payment_link(&creator_links.links, &link_id);
//         assert!(link_found, E_PAYMENT_LINK_NOT_FOUND);

//         let payment_link = vector::borrow(&creator_links.links, link_index);
//         (
//             payment_link.title,
//             payment_link.description,
//             payment_link.amount,
//             payment_link.status,
//             payment_link.total_payments,
//             payment_link.current_uses
//         )
//     }

//     #[view]
//     public fun get_creator_earnings(creator_addr: address): u64 acquires CreatorPaymentLinks {
//         let creator_links = borrow_global<CreatorPaymentLinks>(creator_addr);
//         creator_links.total_earnings
//     }

//     #[view]
//     public fun get_payment_count(creator_addr: address): u64 acquires CreatorPaymentLinks {
//         let creator_links = borrow_global<CreatorPaymentLinks>(creator_addr);
//         vector::length(&creator_links.payments)
//     }
// }