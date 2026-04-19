//
//  LocalSessionStoring.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation

protocol LocalSessionStoring {
    func loadSession(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) -> RatchetSession?

    func saveSession(_ session: RatchetSession) throws
    func deleteSession(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) throws
}

@MainActor
final class LocalSessionStore: LocalSessionStoring {
    private let encryptedStore: EncryptedFileStore

    init(encryptedStore: EncryptedFileStore? = nil) {
        self.encryptedStore = encryptedStore ?? EncryptedFileStore()
    }

    func loadSession(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) -> RatchetSession? {
        do {
            return try encryptedStore.load(
                RatchetSession.self,
                from: storagePath(
                    conversationID: conversationID,
                    localUserID: localUserID,
                    remoteUserID: remoteUserID
                )
            )
        } catch {
            return nil
        }
    }

    func saveSession(_ session: RatchetSession) throws {
        try encryptedStore.save(
            session,
            to: storagePath(
                conversationID: session.conversationID,
                localUserID: session.localUserID,
                remoteUserID: session.remoteUserID
            )
        )
    }

    func deleteSession(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) throws {
        try encryptedStore.delete(
            at: storagePath(
                conversationID: conversationID,
                localUserID: localUserID,
                remoteUserID: remoteUserID
            )
        )
    }

    private func storagePath(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) -> String {
        "sessions/\(localUserID)_\(remoteUserID)_\(conversationID.uuidString).json.enc"
    }
}
