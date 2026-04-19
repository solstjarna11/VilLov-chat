import Foundation
import Testing

@testable import VilLov_Chat

struct RatchetReplayTests {

    @Test
    @MainActor
    func duplicate_message_should_fail_without_corrupting_session() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(bootstrap) == "bootstrap")

        let m1 = try await alice.send("hello", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(m1) == "hello")

        do {
            _ = try await bob.receive(m1)
            Issue.record("Duplicate message unexpectedly decrypted")
        } catch {
            // expected
        }

        let m2 = try await alice.send("next", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(m2) == "next")
    }

    @Test
    @MainActor
    func duplicate_bootstrap_message_should_fail_without_corrupting_session() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(bootstrap) == "bootstrap")

        do {
            _ = try await bob.receive(bootstrap)
            Issue.record("Duplicate bootstrap message unexpectedly decrypted")
        } catch {
            // expected
        }

        let m1 = try await alice.send("after duplicate bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(m1) == "after duplicate bootstrap")
    }
}