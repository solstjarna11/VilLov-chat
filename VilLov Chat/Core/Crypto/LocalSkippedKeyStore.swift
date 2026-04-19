//
//  LocalSkippedKeyStore.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation

@MainActor
final class LocalSkippedKeyStore {
    private let encryptedStore: EncryptedFileStore
    private let maxStoredKeys = 200

    init(encryptedStore: EncryptedFileStore? = nil) {
        self.encryptedStore = encryptedStore ?? EncryptedFileStore()
    }

    func loadAll(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) -> [SkippedMessageKey] {
        do {
            return try encryptedStore.load(
                [SkippedMessageKey].self,
                from: storagePath(
                    conversationID: conversationID,
                    localUserID: localUserID,
                    remoteUserID: remoteUserID
                )
            ) ?? []
        } catch {
            return []
        }
    }

    func saveAll(
        _ keys: [SkippedMessageKey],
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) throws {
        let trimmed = Array(
            keys
                .sorted { $0.createdAt < $1.createdAt }
                .suffix(maxStoredKeys)
        )

        try encryptedStore.save(
            trimmed,
            to: storagePath(
                conversationID: conversationID,
                localUserID: localUserID,
                remoteUserID: remoteUserID
            )
        )
    }

    func store(_ key: SkippedMessageKey) throws {
        var existing = loadAll(
            conversationID: key.conversationID,
            localUserID: key.localUserID,
            remoteUserID: key.remoteUserID
        )

        guard !existing.contains(where: { $0.id == key.id }) else { return }

        existing.append(key)

        try saveAll(
            existing,
            conversationID: key.conversationID,
            localUserID: key.localUserID,
            remoteUserID: key.remoteUserID
        )
    }

    func takeKey(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String,
        messageNumber: Int
    ) throws -> SkippedMessageKey? {
        var existing = loadAll(
            conversationID: conversationID,
            localUserID: localUserID,
            remoteUserID: remoteUserID
        )

        guard let index = existing.firstIndex(where: { $0.messageNumber == messageNumber }) else {
            return nil
        }

        let key = existing.remove(at: index)

        try saveAll(
            existing,
            conversationID: conversationID,
            localUserID: localUserID,
            remoteUserID: remoteUserID
        )

        return key
    }

    private func storagePath(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) -> String {
        "skipped/\(localUserID)_\(remoteUserID)_\(conversationID.uuidString).json.enc"
    }
}