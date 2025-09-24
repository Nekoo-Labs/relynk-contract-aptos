// module relynk::relynk_core {
//     use std::string::{Self, String};
//     use std::signer;
//     use std::vector;
//     use aptos_framework::account;
//     use aptos_framework::event::{Self, EventHandle};
//     use aptos_framework::timestamp;

//     friend relynk::PaymentLinks;

//     const E_ALREADY_INITIALIZED: u64 = 1;
//     const E_PROFILE_NOT_FOUND: u64 = 2;
//     const E_PROFILE_EXISTS: u64 = 3;
//     const E_NOT_AUTHORIZED: u64 = 4;
//     const E_HANDLE_TAKEN: u64 = 5;
//     const E_PROTOCOL_PAUSED: u64 = 6;
//     const E_INVALID_FEE_BPS: u64 = 7;
//     const E_PROFILE_INACTIVE: u64 = 8;

//     struct RelynkState has key {
//         admin: address,
//         protocol_fee_bps: u64,
//         next_profile_id: u64,
//         total_profiles: u64,
//         total_protocol_volume: u64,
//         total_protocol_transactions: u64,
//         is_paused: bool,
//         profile_registered_events: EventHandle<ProfileRegisteredEvent>,
//         profile_updated_events: EventHandle<ProfileUpdatedEvent>,
//         verification_events: EventHandle<ProfileVerificationEvent>,
//     }

//     struct HandleRegistry has key {
//         mappings: vector<HandleMapping>,
//     }

//     struct HandleMapping has store {
//         handle: String,
//         owner: address,
//     }

//     struct CreatorProfile has key, store {
//         profile_id: u64,
//         handle: String,
//         metadata_uri: String,
//         metadata_hash: vector<u8>,
//         owner: address,
//         is_verified: bool,
//         is_active: bool,
//         created_at: u64,
//         updated_at: u64,
//         total_volume: u64,
//         total_transactions: u64,
//     }

//     struct ProfileRegisteredEvent has drop, store {
//         profile_id: u64,
//         owner: address,
//         handle: String,
//         metadata_uri: String,
//         timestamp: u64,
//     }

//     struct ProfileUpdatedEvent has drop, store {
//         profile_id: u64,
//         owner: address,
//         field: String,
//         value: String,
//         timestamp: u64,
//     }

//     struct ProfileVerificationEvent has drop, store {
//         profile_id: u64,
//         owner: address,
//         is_verified: bool,
//         timestamp: u64,
//     }

//     public entry fun initialize(admin: &signer) {
//         let admin_addr = signer::address_of(admin);
//         assert!(admin_addr == @relynk, E_NOT_AUTHORIZED);
//         assert!(!exists<RelynkState>(@relynk), E_ALREADY_INITIALIZED);
//         assert!(!exists<HandleRegistry>(@relynk), E_ALREADY_INITIALIZED);

//         move_to(admin, RelynkState {
//             admin: admin_addr,
//             protocol_fee_bps: 250,
//             next_profile_id: 1,
//             total_profiles: 0,
//             total_protocol_volume: 0,
//             total_protocol_transactions: 0,
//             is_paused: false,
//             profile_registered_events: account::new_event_handle<ProfileRegisteredEvent>(admin),
//             profile_updated_events: account::new_event_handle<ProfileUpdatedEvent>(admin),
//             verification_events: account::new_event_handle<ProfileVerificationEvent>(admin),
//         });

//         move_to(admin, HandleRegistry {
//             mappings: vector::empty<HandleMapping>(),
//         });
//     }

//     public entry fun register_profile(
//         creator: &signer,
//         handle: String,
//         metadata_uri: String,
//         metadata_hash: vector<u8>,
//     ) acquires RelynkState, HandleRegistry, CreatorProfile {
//         assert_protocol_active();
//         let creator_addr = signer::address_of(creator);
//         assert!(!exists<CreatorProfile>(creator_addr), E_PROFILE_EXISTS);

//         let handle_copy_for_lookup = string::utf8(string::bytes(&handle));
//         let handle_copy_for_event = string::utf8(string::bytes(&handle));
//         let metadata_uri_for_event = string::utf8(string::bytes(&metadata_uri));

//         let state = borrow_global_mut<RelynkState>(@relynk);
//         let profile_id = state.next_profile_id;
//         state.next_profile_id = profile_id + 1;
//         state.total_profiles = state.total_profiles + 1;

//         let registry = borrow_global_mut<HandleRegistry>(@relynk);
//         assert!(!handle_exists(&registry.mappings, &handle_copy_for_lookup), E_HANDLE_TAKEN);
//         vector::push_back(&mut registry.mappings, HandleMapping {
//             handle: handle_copy_for_lookup,
//             owner: creator_addr,
//         });

//         let now = timestamp::now_seconds();
//         move_to(creator, CreatorProfile {
//             profile_id: profile_id,
//             handle: handle,
//             metadata_uri: metadata_uri,
//             metadata_hash: metadata_hash,
//             owner: creator_addr,
//             is_verified: false,
//             is_active: true,
//             created_at: now,
//             updated_at: now,
//             total_volume: 0,
//             total_transactions: 0,
//         });

//         event::emit_event(&mut state.profile_registered_events, ProfileRegisteredEvent {
//             profile_id: profile_id,
//             owner: creator_addr,
//             handle: handle_copy_for_event,
//             metadata_uri: metadata_uri_for_event,
//             timestamp: now,
//         });
//     }

//     public entry fun update_profile_metadata(
//         creator: &signer,
//         metadata_uri: String,
//         metadata_hash: vector<u8>,
//     ) acquires CreatorProfile, RelynkState {
//         let creator_addr = signer::address_of(creator);
//         let profile = borrow_global_mut<CreatorProfile>(creator_addr);
//         assert!(profile.owner == creator_addr, E_NOT_AUTHORIZED);
//         assert!(profile.is_active, E_PROFILE_INACTIVE);

//         profile.metadata_uri = metadata_uri;
//         profile.metadata_hash = metadata_hash;
//         let now = timestamp::now_seconds();
//         profile.updated_at = now;

//         let state = borrow_global_mut<RelynkState>(@relynk);
//         event::emit_event(&mut state.profile_updated_events, ProfileUpdatedEvent {
//             profile_id: profile.profile_id,
//             owner: creator_addr,
//             field: string::utf8(b"metadata"),
//             value: string::utf8(string::bytes(&profile.metadata_uri)),
//             timestamp: now,
//         });
//     }

//     public entry fun update_profile_handle(
//         creator: &signer,
//         new_handle: String,
//     ) acquires CreatorProfile, HandleRegistry, RelynkState {
//         let creator_addr = signer::address_of(creator);
//         let profile = borrow_global_mut<CreatorProfile>(creator_addr);
//         assert!(profile.owner == creator_addr, E_NOT_AUTHORIZED);
//         assert!(profile.is_active, E_PROFILE_INACTIVE);

//         let registry = borrow_global_mut<HandleRegistry>(@relynk);
//         assert!(!handle_exists(&registry.mappings, &new_handle), E_HANDLE_TAKEN);

//         let old_handle_copy = string::utf8(string::bytes(&profile.handle));
//         remove_handle_mapping(&mut registry.mappings, &old_handle_copy);

//         let handle_for_registry = string::utf8(string::bytes(&new_handle));
//         vector::push_back(&mut registry.mappings, HandleMapping {
//             handle: handle_for_registry,
//             owner: creator_addr,
//         });

//         profile.handle = new_handle;
//         let now = timestamp::now_seconds();
//         profile.updated_at = now;

//         let state = borrow_global_mut<RelynkState>(@relynk);
//         event::emit_event(&mut state.profile_updated_events, ProfileUpdatedEvent {
//             profile_id: profile.profile_id,
//             owner: creator_addr,
//             field: string::utf8(b"handle"),
//             value: string::utf8(string::bytes(&profile.handle)),
//             timestamp: now,
//         });
//     }

//     public entry fun set_profile_active_state(
//         admin: &signer,
//         creator_addr: address,
//         should_be_active: bool,
//     ) acquires CreatorProfile, RelynkState {
//         ensure_admin(admin);
//         let profile = borrow_global_mut<CreatorProfile>(creator_addr);
//         profile.is_active = should_be_active;
//         profile.updated_at = timestamp::now_seconds();
//     }

//     public entry fun verify_profile(
//         admin: &signer,
//         creator_addr: address,
//         is_verified: bool,
//     ) acquires CreatorProfile, RelynkState {
//         ensure_admin(admin);
//         let profile = borrow_global_mut<CreatorProfile>(creator_addr);
//         profile.is_verified = is_verified;
//         let now = timestamp::now_seconds();
//         profile.updated_at = now;

//         let state = borrow_global_mut<RelynkState>(@relynk);
//         event::emit_event(&mut state.verification_events, ProfileVerificationEvent {
//             profile_id: profile.profile_id,
//             owner: creator_addr,
//             is_verified: is_verified,
//             timestamp: now,
//         });
//     }

//     public entry fun update_protocol_fee(
//         admin: &signer,
//         new_fee_bps: u64,
//     ) acquires RelynkState {
//         ensure_admin(admin);
//         assert!(new_fee_bps <= 1000, E_INVALID_FEE_BPS);
//         let state = borrow_global_mut<RelynkState>(@relynk);
//         state.protocol_fee_bps = new_fee_bps;
//     }

//     public entry fun toggle_pause(admin: &signer, pause: bool) acquires RelynkState {
//         ensure_admin(admin);
//         let state = borrow_global_mut<RelynkState>(@relynk);
//         state.is_paused = pause;
//     }

//     public fun calculate_protocol_fee(amount: u64): u64 acquires RelynkState {
//         let state = borrow_global<RelynkState>(@relynk);
//         (amount * state.protocol_fee_bps) / 10000
//     }

//     public(friend) fun record_creator_activity(
//         creator_addr: address,
//         gross_amount: u64,
//     ) acquires CreatorProfile, RelynkState {
//         let profile = borrow_global_mut<CreatorProfile>(creator_addr);
//         assert!(profile.is_active, E_PROFILE_INACTIVE);
//         profile.total_volume = profile.total_volume + gross_amount;
//         profile.total_transactions = profile.total_transactions + 1;
//         profile.updated_at = timestamp::now_seconds();

//         let state = borrow_global_mut<RelynkState>(@relynk);
//         state.total_protocol_volume = state.total_protocol_volume + gross_amount;
//         state.total_protocol_transactions = state.total_protocol_transactions + 1;
//     }

//     #[view]
//     public fun get_profile(creator_addr: address): (u64, String, String, bool, bool, u64, u64, u64, u64)
//     acquires CreatorProfile {
//         assert!(exists<CreatorProfile>(creator_addr), E_PROFILE_NOT_FOUND);
//         let profile = borrow_global<CreatorProfile>(creator_addr);
//         (
//             profile.profile_id,
//             string::utf8(string::bytes(&profile.handle)),
//             string::utf8(string::bytes(&profile.metadata_uri)),
//             profile.is_verified,
//             profile.is_active,
//             profile.total_volume,
//             profile.total_transactions,
//             profile.created_at,
//             profile.updated_at
//         )
//     }

//     #[view]
//     public fun resolve_handle(handle: String): address acquires HandleRegistry {
//         let registry = borrow_global<HandleRegistry>(@relynk);
//         let (found, idx) = find_handle_index(&registry.mappings, &handle);
//         if (found) {
//             let entry = vector::borrow(&registry.mappings, idx);
//             entry.owner
//         } else {
//             @0x0
//         }
//     }

//     #[view]
//     public fun get_protocol_stats(): (u64, u64, u64, u64, bool) acquires RelynkState {
//         let state = borrow_global<RelynkState>(@relynk);
//         (
//             state.total_profiles,
//             state.total_protocol_volume,
//             state.total_protocol_transactions,
//             state.protocol_fee_bps,
//             state.is_paused
//         )
//     }

//     fun ensure_admin(admin: &signer) acquires RelynkState {
//         let admin_addr = signer::address_of(admin);
//         let state = borrow_global<RelynkState>(@relynk);
//         assert!(admin_addr == state.admin, E_NOT_AUTHORIZED);
//     }

//     fun assert_protocol_active() acquires RelynkState {
//         let state = borrow_global<RelynkState>(@relynk);
//         assert!(!state.is_paused, E_PROTOCOL_PAUSED);
//     }

//     fun handle_exists(mappings: &vector<HandleMapping>, handle: &String): bool {
//         let i = 0;
//         let len = vector::length(mappings);
//         while (i < len) {
//             let entry = vector::borrow(mappings, i);
//             if (string::equals(&entry.handle, handle)) {
//                 return true
//             };
//             i = i + 1;
//         };
//         false
//     }

//     fun remove_handle_mapping(mappings: &mut vector<HandleMapping>, handle: &String) {
//         let (found, idx) = find_handle_index(mappings, handle);
//         if (found) {
//             vector::swap_remove(mappings, idx);
//         }
//     }

//     fun find_handle_index(mappings: &vector<HandleMapping>, handle: &String): (bool, u64) {
//         let i = 0;
//         let len = vector::length(mappings);
//         while (i < len) {
//             let entry = vector::borrow(mappings, i);
//             if (string::equals(&entry.handle, handle)) {
//                 return (true, i)
//             };
//             i = i + 1;
//         };
//         (false, 0)
//     }
// }
