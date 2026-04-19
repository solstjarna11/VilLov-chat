//
//  LocalMessageStoreTests.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import XCTest
@testable import VilLov_Chat

@MainActor
final class LocalMessageStoreTests: XCTestCase {
    private var store: LocalMessageStore!
    private var encryptedStore: EncryptedFileStore!
    private var keyManager: LocalStorageKeyManager!

    override func setUp() {
        super.setUp()
        let isolated = StorageTestSupport.makeIsolatedEncryptedStore(testName: "LocalMessageStoreTests")
        self.encryptedStore = isolated.0
        self.keyManager = isolated.1
        self.store = LocalMessageStore(encryptedStore: encryptedStore)
    }

    override func tearDown() {
        StorageTestSupport.cleanup(store: encryptedStore, keyManager: keyManager)
        store = nil
        encryptedStore = nil
        keyManager = nil
        super.tearDown()
    }

    func testAppendAndLoadMessagesRoundTrips() {
        let conversationID = UUID()
        let currentUserID = "alice"

        let message = Message(
            id: UUID(),
            text: "Hello",
            isIncoming: false,
            timestamp: Date(),
            status: .sent
        )

        _ = store.appendMessage(message, for: conversationID, currentUserID: currentUserID)

        let loaded = store.loadMessages(for: conversationID, currentUserID: currentUserID)

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.text, "Hello")
        XCTAssertEqual(loaded.first?.status, .sent)
    }

    func testMergeIncomingMessagesDoesNotDuplicateByID() {
        let conversationID = UUID()
        let currentUserID = "alice"
        let id = UUID()
        let timestamp = Date()

        let message = Message(
            id: id,
            text: "Incoming",
            isIncoming: true,
            timestamp: timestamp,
            status: .sent
        )

        _ = store.mergeIncomingMessages([message], for: conversationID, currentUserID: currentUserID)
        let merged = store.mergeIncomingMessages([message], for: conversationID, currentUserID: currentUserID)

        XCTAssertEqual(merged.count, 1)
    }

    func testReplaceMessageUpdatesExistingMessage() {
        let conversationID = UUID()
        let currentUserID = "alice"
        let id = UUID()
        let timestamp = Date()

        let initial = Message(
            id: id,
            text: "Old",
            isIncoming: false,
            timestamp: timestamp,
            status: .sending
        )

        _ = store.appendMessage(initial, for: conversationID, currentUserID: currentUserID)

        let updated = Message(
            id: id,
            text: "Old",
            isIncoming: false,
            timestamp: timestamp,
            status: .sent
        )

        let result = store.replaceMessage(updated, for: conversationID, currentUserID: currentUserID)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.status, .sent)
    }

    func testStoredMessagesAreEncryptedAtRest() throws {
        let conversationID = UUID()
        let currentUserID = "alice"
        let plaintext = "VISIBLE_SECRET"

        let message = Message(
            id: UUID(),
            text: plaintext,
            isIncoming: false,
            timestamp: Date(),
            status: .sent
        )

        _ = store.appendMessage(message, for: conversationID, currentUserID: currentUserID)

        let relativePath = "messages/\(currentUserID)_\(conversationID.uuidString).json.enc"
        let raw = try XCTUnwrap(encryptedStore.rawFileData(at: relativePath))
        let rawString = String(data: raw, encoding: .utf8)

        XCTAssertFalse(rawString?.contains(plaintext) ?? false)
    }
}