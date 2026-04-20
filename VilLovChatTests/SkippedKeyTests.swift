//
//  SkippedKeyTests.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import Testing

@testable import VilLov_Chat

struct SkippedKeyTests {

    @Test
    @MainActor
    func skipped_key_is_consumed_once() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(bootstrap) == "bootstrap")

        let m1 = try await alice.send("first", to: bob, conversationID: conversationID)
        let m2 = try await alice.send("second", to: bob, conversationID: conversationID)

        #expect(try await bob.receive(m2) == "second")
        #expect(try await bob.receive(m1) == "first")

        do {
            _ = try await bob.receive(m1)
            Issue.record("Previously consumed skipped key unexpectedly reused")
        } catch {
            // expected
        }
    }

    @Test
    @MainActor
    func skipped_multiple_messages_can_be_recovered() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(bootstrap) == "bootstrap")

        let m1 = try await alice.send("1", to: bob, conversationID: conversationID)
        let m2 = try await alice.send("2", to: bob, conversationID: conversationID)
        let m3 = try await alice.send("3", to: bob, conversationID: conversationID)

        #expect(try await bob.receive(m3) == "3")
        #expect(try await bob.receive(m1) == "1")
        #expect(try await bob.receive(m2) == "2")
    }
}