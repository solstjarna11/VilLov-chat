import Foundation
import Testing

@testable import VilLov_Chat

struct SessionCorruptionTests {

    @Test
    @MainActor
    func corrupted_persisted_session_fails_closed() async throws {
        let alice = TestClient.make(userID: "alice-\(UUID().uuidString)")
        let bob = TestClient.make(userID: "bob-\(UUID().uuidString)")
        let conversationID = TestConversationIDs.deterministic(alice.userID, bob.userID)

        let bootstrap = try await alice.send("bootstrap", to: bob, conversationID: conversationID)
        #expect(try await bob.receive(bootstrap) == "bootstrap")

        try bob.localSessionStore.overwriteRawSessionDataForTesting(
            Data("definitely-not-a-valid-session".utf8),
            conversationID: conversationID,
            localUserID: bob.userID,
            remoteUserID: alice.userID
        )

        let next = try await alice.send("after corruption", to: bob, conversationID: conversationID)

        do {
            _ = try await bob.receive(next)
            Issue.record("Corrupted persisted session unexpectedly decrypted")
        } catch {
            // expected: fail closed
        }
    }
}