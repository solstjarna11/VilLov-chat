//
//  EncryptedFileStore.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
import CryptoKit

enum EncryptedFileStoreError: Error {
    case fileURLResolutionFailed
    case invalidCiphertext
}

final class EncryptedFileStore {
    private let keyManager: LocalStorageKeyManager
    private let directoryName = "EncryptedLocalStore"

    init(keyManager: LocalStorageKeyManager = LocalStorageKeyManager()) {
        self.keyManager = keyManager
    }

    func save<T: Encodable>(_ value: T, to relativePath: String) throws {
        let encoder = JSONEncoder()
        let plaintext = try encoder.encode(value)

        let key = try keyManager.loadOrCreateMasterKey()
        let sealed = try AES.GCM.seal(plaintext, using: key)

        guard let combined = sealed.combined else {
            throw EncryptedFileStoreError.invalidCiphertext
        }

        let fileURL = try url(for: relativePath)
        try ensureDirectoryExists(for: fileURL)
        try combined.write(to: fileURL, options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, from relativePath: String) throws -> T? {
        let fileURL = try url(for: relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let encrypted = try Data(contentsOf: fileURL)
        let key = try keyManager.loadOrCreateMasterKey()

        let sealedBox = try AES.GCM.SealedBox(combined: encrypted)
        let plaintext = try AES.GCM.open(sealedBox, using: key)

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: plaintext)
    }

    func delete(at relativePath: String) throws {
        let fileURL = try url(for: relativePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        try FileManager.default.removeItem(at: fileURL)
    }

    private func url(for relativePath: String) throws -> URL {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw EncryptedFileStoreError.fileURLResolutionFailed
        }
        return base.appendingPathComponent(directoryName).appendingPathComponent(relativePath)
    }

    private func ensureDirectoryExists(for fileURL: URL) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }
}
