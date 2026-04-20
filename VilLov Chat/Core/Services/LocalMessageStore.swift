//
//  LocalMessageStore.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 17.4.2026.
//

import Foundation

struct StoredConversationMessage: Codable, Equatable, Identifiable {
    let id: UUID
    let conversationID: UUID
    let text: String
    let isIncoming: Bool
    let timestamp: Date
    let status: MessageStatus
}

@MainActor
final class LocalMessageStore {
    private let encryptedStore: EncryptedFileStore

    init(encryptedStore: EncryptedFileStore? = nil) {
        self.encryptedStore = encryptedStore ?? EncryptedFileStore()
    }

    func loadMessages(for conversationID: UUID, currentUserID: String) -> [Message] {
        let relativePath = storagePath(for: conversationID, currentUserID: currentUserID)

        do {
            let stored = try encryptedStore.load([StoredConversationMessage].self, from: relativePath) ?? []
            return stored
                .map {
                    Message(
                        id: $0.id,
                        text: $0.text,
                        isIncoming: $0.isIncoming,
                        timestamp: $0.timestamp,
                        status: $0.status
                    )
                }
                .sorted { $0.timestamp < $1.timestamp }
        } catch {
            return []
        }
    }

    func saveMessages(_ messages: [Message], for conversationID: UUID, currentUserID: String) {
        let stored = messages.map {
            StoredConversationMessage(
                id: $0.id,
                conversationID: conversationID,
                text: $0.text,
                isIncoming: $0.isIncoming,
                timestamp: $0.timestamp,
                status: $0.status
            )
        }

        do {
            try encryptedStore.save(
                stored,
                to: storagePath(for: conversationID, currentUserID: currentUserID)
            )
        } catch {
            return
        }
    }

    func mergeIncomingMessages(
        _ newMessages: [Message],
        for conversationID: UUID,
        currentUserID: String
    ) -> [Message] {
        var existing = loadMessages(for: conversationID, currentUserID: currentUserID)

        for newMessage in newMessages {
            guard !existing.contains(where: { $0.id == newMessage.id }) else { continue }
            existing.append(newMessage)
        }

        existing.sort { $0.timestamp < $1.timestamp }
        saveMessages(existing, for: conversationID, currentUserID: currentUserID)
        return existing
    }

    func appendMessage(
        _ message: Message,
        for conversationID: UUID,
        currentUserID: String
    ) -> [Message] {
        var existing = loadMessages(for: conversationID, currentUserID: currentUserID)
        existing.append(message)
        existing.sort { $0.timestamp < $1.timestamp }
        saveMessages(existing, for: conversationID, currentUserID: currentUserID)
        return existing
    }

    func replaceMessage(
        _ message: Message,
        for conversationID: UUID,
        currentUserID: String
    ) -> [Message] {
        var existing = loadMessages(for: conversationID, currentUserID: currentUserID)

        if let index = existing.firstIndex(where: { $0.id == message.id }) {
            existing[index] = message
        } else {
            existing.append(message)
        }

        existing.sort { $0.timestamp < $1.timestamp }
        saveMessages(existing, for: conversationID, currentUserID: currentUserID)
        return existing
    }

    private func storagePath(for conversationID: UUID, currentUserID: String) -> String {
        "messages/\(currentUserID)_\(conversationID.uuidString).json.enc"
    }
}
