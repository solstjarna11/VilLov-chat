//
//  LocalSkippedKeyStoreTests.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import XCTest
@testable import VilLov_Chat

@MainActor
final class LocalSkippedKeyStoreTests: XCTestCase {
    private var store: LocalSkippedKeyStore!
    private var encryptedStore: EncryptedFileStore!
    private var keyManager: LocalStorageKeyManager!

    override func setUp() {
        super.setUp()
        let isolated = StorageTestSupport.makeIsolatedEncryptedStore(testName: "LocalSkippedKeyStoreTests")
        self.encryptedStore = isolated.0
        self.keyManager = isolated.1
        self.store = LocalSkippedKeyStore(encryptedStore: encryptedStore)
    }

    override func tearDown() {
        StorageTestSupport.cleanup(store: encryptedStore, keyManager: keyManager)
        store = nil
        encryptedStore = nil
        keyManager = nil
        super.tearDown()
    }

    func testStoreAndTakeKeyRoundTripsAndConsumesOnce() throws {
        let conversationID = UUID()
        let key = SkippedMessageKey(
            conversationID: conversationID,
            localUserID: "alice",
            remoteUserID: "bob",
            messageNumber: 7,
            keyData: Data("message-key".utf8)
        )

        try store.store(key)

        let taken = try store.takeKey(
            conversationID: conversationID,
            localUserID: "alice",
            remoteUserID: "bob",
            messageNumber: 7
        )

        XCTAssertEqual(taken, key)

        let takenAgain = try store.takeKey(
            conversationID: conversationID,
            localUserID: "alice",
            remoteUserID: "bob",
            messageNumber: 7
        )

        XCTAssertNil(takenAgain)
    }

    func testDuplicateStoreDoesNotDuplicateEntry() throws {
        let conversationID = UUID()
        let key = SkippedMessageKey(
            conversationID: conversationID,
            localUserID: "alice",
            remoteUserID: "bob",
            messageNumber: 3,
            keyData: Data("message-key".utf8)
        )

        try store.store(key)
        try store.store(key)

        let loaded = store.loadAll(
            conversationID: conversationID,
            localUserID: "alice",
            remoteUserID: "bob"
        )

        XCTAssertEqual(loaded.count, 1)
    }

    func testStoredSkippedKeysAreEncryptedAtRest() throws {
        let conversationID = UUID()
        let key = SkippedMessageKey(
            conversationID: conversationID,
            localUserID: "alice",
            remoteUserID: "bob",
            messageNumber: 5,
            keyData: Data("VISIBLE_SKIPPED_KEY".utf8)
        )

        try store.store(key)

        let relativePath = "skipped/alice_bob_\(conversationID.uuidString).json.enc"
        let raw = try XCTUnwrap(encryptedStore.rawFileData(at: relativePath))
        let rawString = String(data: raw, encoding: .utf8)

        XCTAssertFalse(rawString?.contains("VISIBLE_SKIPPED_KEY") ?? false)
    }
}