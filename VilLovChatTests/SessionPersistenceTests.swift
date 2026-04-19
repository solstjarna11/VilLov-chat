import Foundation
import Testing

@testable import VilLov_Chat

struct SessionPersistenceTests {

    @Test
    @MainActor
    func session_survives_engine_reload() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let m1 = try await alice.send("before reload", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(m1) == "before reload")

        let reloadedBob = bob.reload()

        let m2 = try await alice.send("after reload", to: reloadedBob, conversationID: conversationID)
        #expect(try await reloadedBob.receive(m2) == "after reload")
    }
}