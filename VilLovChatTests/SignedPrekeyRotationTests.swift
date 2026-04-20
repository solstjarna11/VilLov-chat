//
//  SignedPrekeyRotationTests.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 20.4.2026.
//


import Foundation
import Testing

@testable import VilLov_Chat

struct SignedPrekeyRotationTests {

    @Test
    @MainActor
    func first_message_bootstrap_succeeds_with_current_signed_prekey() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let message = try await alice.send("hello", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(message) == "hello")
    }

    @Test
    @MainActor
    func bootstrap_still_succeeds_after_local_signed_prekey_rotation_when_header_references_old_signed_prekey_id() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        // Alice fetches Bob's bundle before rotation.
        let oldBundle = try bob.recipientBundle()

        // Bob rotates locally after Alice already fetched the old bundle.
        try bob.rotateSignedPrekey()

        // Alice encrypts using the old bundle; header should carry old signedPrekeyId.
        let delayedBootstrap = try await alice.send(
            "delayed bootstrap",
            to: bob,
            using: oldBundle,
            conversationID: conversationID
        )

        #expect(try await bob.receive(delayedBootstrap) == "delayed bootstrap")
    }

    @Test
    @MainActor
    func bootstrap_fails_with_missing_required_local_signed_prekey_after_retired_key_is_purged() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        // Alice fetches a bundle bound to Bob's current signed prekey.
        let oldBundle = try bob.recipientBundle()

        // Bob rotates, then purges all retired signed prekeys.
        try bob.rotateSignedPrekey()
        try bob.purgeRetiredSignedPrekeys(olderThan: Date().addingTimeInterval(1))

        let delayedBootstrap = try await alice.send(
            "should fail",
            to: bob,
            using: oldBundle,
            conversationID: conversationID
        )

        do {
            _ = try await bob.receive(delayedBootstrap)
            Issue.record("Bootstrap unexpectedly decrypted after old signed prekey was purged")
        } catch let error as E2EEError {
            #expect(error == .missingRequiredLocalSignedPrekey)
        }
    }

    @Test
    @MainActor
    func existing_ratchet_session_continues_working_after_signed_prekey_rotation() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(bootstrap) == "bootstrap")

        // Session now exists on both sides.
        try bob.rotateSignedPrekey()

        let next = try await alice.send("after rotation", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(next) == "after rotation")
    }

    @Test
    @MainActor
    func recipient_bundle_signature_verification_fails_if_signed_prekey_id_is_tampered_with() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let tamperedBundle = try bob.tamperedRecipientBundleChangingSignedPrekeyId()

        do {
            _ = try await alice.send(
                "should not encrypt",
                to: bob,
                using: tamperedBundle,
                conversationID: conversationID
            )
            Issue.record("Encryption unexpectedly succeeded with tampered signedPrekeyId")
        } catch let error as E2EEError {
            #expect(error == .invalidRecipientSignedPrekeySignature)
        }
    }

    @Test
    @MainActor
    func recipient_bundle_signature_verification_fails_if_signed_prekey_is_tampered_with() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let tamperedBundle = try bob.tamperedRecipientBundleChangingSignedPrekey()

        do {
            _ = try await alice.send(
                "should not encrypt",
                to: bob,
                using: tamperedBundle,
                conversationID: conversationID
            )
            Issue.record("Encryption unexpectedly succeeded with tampered signedPrekey")
        } catch let error as E2EEError {
            #expect(error == .invalidRecipientSignedPrekeySignature)
        }
    }
}
