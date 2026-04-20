//
//  RatchetTests.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import Testing

@testable import VilLov_Chat

struct RatchetTests {

    @Test
    @MainActor
    func alternating_messages_roundtrip() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let m1 = try await alice.send("hello bob", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(m1) == "hello bob")

        let m2 = try await bob.send("hello alice", to: alice, conversationID: conversationID)
        #expect(try await alice.receive(m2) == "hello alice")

        let m3 = try await alice.send("third", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(m3) == "third")

        let m4 = try await bob.send("fourth", to: alice, conversationID: conversationID)
        #expect(try await alice.receive(m4) == "fourth")
    }

    @Test
    @MainActor
    func same_sender_multiple_messages_roundtrip() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(bootstrap) == "bootstrap")

        let m1 = try await alice.send("1", to: bob, conversationID: conversationID)
        let m2 = try await alice.send("2", to: bob, conversationID: conversationID)
        let m3 = try await alice.send("3", to: bob, conversationID: conversationID)

        #expect(try await bob.receive(m1) == "1")
        #expect(try await bob.receive(m2) == "2")
        #expect(try await bob.receive(m3) == "3")
    }

    @Test
    @MainActor
    func out_of_order_delivery_after_bootstrap_uses_skipped_keys() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(bootstrap) == "bootstrap")

        let m1 = try await alice.send("first", to: bob, conversationID: conversationID)
        let m2 = try await alice.send("second", to: bob, conversationID: conversationID)

        #expect(try await bob.receive(m2) == "second")
        #expect(try await bob.receive(m1) == "first")
    }
}
