//
//  EncryptedFileStoreTests.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import XCTest
@testable import VilLov_Chat

final class EncryptedFileStoreTests: XCTestCase {
    private var store: EncryptedFileStore!
    private var keyManager: LocalStorageKeyManager!

    override func setUp() {
        super.setUp()
        let isolated = StorageTestSupport.makeIsolatedEncryptedStore(testName: "EncryptedFileStoreTests")
        self.store = isolated.0
        self.keyManager = isolated.1
    }

    override func tearDown() {
        StorageTestSupport.cleanup(store: store, keyManager: keyManager)
        store = nil
        keyManager = nil
        super.tearDown()
    }

    func testSaveAndLoadRoundTripsCodableValue() throws {
        struct Payload: Codable, Equatable {
            let value: String
            let count: Int
        }

        let payload = Payload(value: "hello", count: 42)
        try store.save(payload, to: "payloads/test.json.enc")

        let loaded = try store.load(Payload.self, from: "payloads/test.json.enc")
        XCTAssertEqual(loaded, payload)
    }

    func testStoredFileDoesNotContainPlaintext() throws {
        struct Payload: Codable, Equatable {
            let secret: String
        }

        let secret = "TOP_SECRET_MESSAGE"
        try store.save(Payload(secret: secret), to: "payloads/secret.json.enc")

        let raw = try XCTUnwrap(store.rawFileData(at: "payloads/secret.json.enc"))
        let rawString = String(data: raw, encoding: .utf8)

        XCTAssertFalse(raw.isEmpty)
        XCTAssertFalse(rawString?.contains(secret) ?? false)
    }

    func testLoadMissingFileReturnsNil() throws {
        let loaded = try store.load(String.self, from: "missing/file.json.enc")
        XCTAssertNil(loaded)
    }

    func testDeleteRemovesStoredValue() throws {
        try store.save(["a", "b", "c"], to: "payloads/list.json.enc")
        XCTAssertNotNil(try store.load([String].self, from: "payloads/list.json.enc"))

        try store.delete(at: "payloads/list.json.enc")

        let loaded = try store.load([String].self, from: "payloads/list.json.enc")
        XCTAssertNil(loaded)
    }
}