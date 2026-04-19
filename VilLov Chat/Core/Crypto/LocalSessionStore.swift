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
    private let defaults: UserDefaults
    private let keyPrefix = "ratchet_session_"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSession(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) -> RatchetSession? {
        let key = storageKey(
            conversationID: conversationID,
            localUserID: localUserID,
            remoteUserID: remoteUserID
        )

        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(RatchetSession.self, from: data)
    }

    func saveSession(_ session: RatchetSession) throws {
        let key = storageKey(
            conversationID: session.conversationID,
            localUserID: session.localUserID,
            remoteUserID: session.remoteUserID
        )

        let data = try JSONEncoder().encode(session)
        defaults.set(data, forKey: key)
    }

    func deleteSession(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) throws {
        let key = storageKey(
            conversationID: conversationID,
            localUserID: localUserID,
            remoteUserID: remoteUserID
        )
        defaults.removeObject(forKey: key)
    }

    private func storageKey(
        conversationID: UUID,
        localUserID: String,
        remoteUserID: String
    ) -> String {
        keyPrefix + localUserID + "_" + remoteUserID + "_" + conversationID.uuidString
    }
}