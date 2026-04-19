//
//  LocalSessionStoreTests.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import XCTest
@testable import VilLov_Chat

@MainActor
final class LocalSessionStoreTests: XCTestCase {
    private var store: LocalSessionStore!
    private var encryptedStore: EncryptedFileStore!
    private var keyManager: LocalStorageKeyManager!

    override func setUp() {
        super.setUp()
        let isolated = StorageTestSupport.makeIsolatedEncryptedStore(testName: "LocalSessionStoreTests")
        self.encryptedStore = isolated.0
        self.keyManager = isolated.1
        self.store = LocalSessionStore(encryptedStore: encryptedStore)
    }

    override func tearDown() {
        StorageTestSupport.cleanup(store: encryptedStore, keyManager: keyManager)
        store = nil
        encryptedStore = nil
        keyManager = nil
        super.tearDown()
    }

    func testSaveAndLoadSessionRoundTrips() throws {
        let session = RatchetSession(
            id: UUID(),
            conversationID: UUID(),
            localUserID: "alice",
            remoteUserID: "bob",
            remoteSigningIdentityKey: "sign-key",
            remoteAgreementIdentityKey: "agree-key",
            rootKey: Data("root".utf8),
            sendingChainKey: Data("send".utf8),
            receivingChainKey: Data("recv".utf8),
            localRatchetPrivateKey: Data("local-ratchet".utf8),
            remoteRatchetPublicKey: Data("remote-ratchet".utf8),
            sendMessageNumber: 2,
            receiveMessageNumber: 3,
            previousSendingChainLength: 1,
            createdAt: Date(),
            updatedAt: Date()
        )

        try store.saveSession(session)

        let loaded = store.loadSession(
            conversationID: session.conversationID,
            localUserID: session.localUserID,
            remoteUserID: session.remoteUserID
        )

        XCTAssertEqual(loaded, session)
    }

    func testDeleteSessionRemovesStoredSession() throws {
        let session = RatchetSession(
            id: UUID(),
            conversationID: UUID(),
            localUserID: "alice",
            remoteUserID: "bob",
            remoteSigningIdentityKey: "sign-key",
            remoteAgreementIdentityKey: "agree-key",
            rootKey: Data("root".utf8),
            sendingChainKey: Data("send".utf8),
            receivingChainKey: Data("recv".utf8),
            localRatchetPrivateKey: Data("local-ratchet".utf8),
            remoteRatchetPublicKey: Data("remote-ratchet".utf8),
            sendMessageNumber: 0,
            receiveMessageNumber: 0,
            previousSendingChainLength: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        try store.saveSession(session)
        try store.deleteSession(
            conversationID: session.conversationID,
            localUserID: session.localUserID,
            remoteUserID: session.remoteUserID
        )

        let loaded = store.loadSession(
            conversationID: session.conversationID,
            localUserID: session.localUserID,
            remoteUserID: session.remoteUserID
        )

        XCTAssertNil(loaded)
    }

    func testStoredSessionIsEncryptedAtRest() throws {
        let session = RatchetSession(
            id: UUID(),
            conversationID: UUID(),
            localUserID: "alice",
            remoteUserID: "bob",
            remoteSigningIdentityKey: "VISIBLE_SIGNING_KEY",
            remoteAgreementIdentityKey: "VISIBLE_AGREEMENT_KEY",
            rootKey: Data("root".utf8),
            sendingChainKey: Data("send".utf8),
            receivingChainKey: Data("recv".utf8),
            localRatchetPrivateKey: Data("local-ratchet".utf8),
            remoteRatchetPublicKey: Data("remote-ratchet".utf8),
            sendMessageNumber: 0,
            receiveMessageNumber: 0,
            previousSendingChainLength: 0,
            createdAt: Date(),
            updatedAt: Date()
        )

        try store.saveSession(session)

        let relativePath = "sessions/\(session.localUserID)_\(session.remoteUserID)_\(session.conversationID.uuidString).json.enc"
        let raw = try XCTUnwrap(encryptedStore.rawFileData(at: relativePath))
        let rawString = String(data: raw, encoding: .utf8)

        XCTAssertFalse(rawString?.contains("VISIBLE_SIGNING_KEY") ?? false)
        XCTAssertFalse(rawString?.contains("VISIBLE_AGREEMENT_KEY") ?? false)
    }
}