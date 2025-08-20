// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module sui::derived_object_tests;

use sui::derived_object;
use sui::test_utils::destroy;

use fun object::new as TxContext.new;

public struct Registry has key { id: UID }

#[test]
fun create_derived_id() {
    let mut ctx = tx_context::dummy();
    let mut registry = Registry { id: ctx.new() };

    let key = b"demo".to_string();
    let another_key = b"another_demo".to_string();

    let derived_id = derived_object::derive_address(registry.id.to_inner(), key);
    let another_derived_id = derived_object::derive_address(registry.id.to_inner(), another_key);

    let derived_uid = registry.id.derive_object(key);
    let another_derived_uid = registry.id.derive_object(another_key);

    assert!(derived_object::exists(&registry.id, key));
    assert!(derived_object::exists(&registry.id, another_key));

    assert!(derived_uid.to_address() == derived_id);
    assert!(another_derived_uid.to_address() == another_derived_id);

    destroy(registry);
    derived_uid.delete();
    another_derived_uid.delete();
}

#[test]
fun multiple_registries_uniqueness() {
    let mut ctx = tx_context::dummy();
    let mut registry = Registry { id: ctx.new() };
    let mut another_registry = Registry { id: ctx.new() };

    let key = b"demo".to_string();

    let derived_uid = registry.id.derive_object(key);
    let another_derived_uid = another_registry.id.derive_object(key);

    assert!(derived_uid.to_address() != another_derived_uid.to_address());

    destroy(registry);
    destroy(another_registry);
    derived_uid.delete();
    another_derived_uid.delete();
}

#[test]
fun test_marker_exists_even_after_deletion() {
    let mut ctx = tx_context::dummy();
    let mut registry = Registry { id: ctx.new() };

    let key = b"persist_test".to_string();
    let derived_uid = registry.id.derive_object(key);

    assert!(derived_object::exists(&registry.id, key));

    derived_uid.delete();

    assert!(derived_object::exists(&registry.id, key));

    destroy(registry);
}

#[test]
fun test_derive_address_deterministic() {
    let mut ctx = tx_context::dummy();
    let registry = Registry { id: ctx.new() };

    let key = b"is deterministic".to_string();

    let addr1 = derived_object::derive_address(registry.id.to_inner(), key);
    let addr2 = derived_object::derive_address(registry.id.to_inner(), key);

    assert!(addr1 == addr2);

    destroy(registry);
}

#[test]
fun test_similar_keys_different_addresses() {
    let mut ctx = tx_context::dummy();
    let registry = Registry { id: ctx.new() };

    let key1 = b"foo".to_string();
    let key2 = b"foo";
    let key3 = b"foo".to_ascii_string();

    let addr1 = derived_object::derive_address(registry.id.to_inner(), key1);
    let addr2 = derived_object::derive_address(registry.id.to_inner(), key2);
    let addr3 = derived_object::derive_address(registry.id.to_inner(), key3);

    assert!(addr1 != addr2);
    assert!(addr1 != addr3);
    assert!(addr2 != addr3);

    destroy(registry);
}

#[test]
fun test_similar_keys_different_addresses_2() {
    let mut ctx = tx_context::dummy();
    let registry = Registry { id: ctx.new() };

    let key1 = vector<u64>[];
    let key2 = vector<u8>[];

    let addr1 = derived_object::derive_address(registry.id.to_inner(), key1);
    let addr2 = derived_object::derive_address(registry.id.to_inner(), key2);

    assert!(addr1 != addr2);

    destroy(registry);
}

#[test, expected_failure(abort_code = derived_object::EObjectAlreadyExists)]
fun try_to_claim_id_twice() {
    let mut ctx = tx_context::dummy();

    let mut registry = Registry { id: object::new(&mut ctx) };
    let key = b"demo".to_string();

    let _uid = registry.id.derive_object(key);
    let _another_uid = registry.id.derive_object(key);

    abort
}
