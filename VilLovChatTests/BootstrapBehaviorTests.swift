//
//  BootstrapBehaviorTests.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import Testing

@testable import VilLov_Chat

struct BootstrapBehaviorTests {

    @Test
    @MainActor
    func post_bootstrap_message_cannot_be_decrypted_before_initial_bootstrap_message() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        let ratcheted = try await alice.send("ratcheted", to: bob, conversationID: conversationID)

        do {
            _ = try await bob.receive(ratcheted)
            Issue.record("Post-bootstrap message decrypted before bootstrap message established session")
        } catch let error as E2EEError {
            #expect(error == .invalidEphemeralPublicKey || error == .invalidHeader || error == .missingSessionBootstrapMaterial || error == .decryptionFailed)
        } catch {
            // acceptable: protocol currently does not support this ordering
        }

        #expect(try await bob.receive(bootstrap) == "bootstrap")
    }

    @Test
    @MainActor
    func initial_bootstrap_message_establishes_session_for_later_messages() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(bootstrap) == "bootstrap")

        let later = try await alice.send("later", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(later) == "later")
    }
}