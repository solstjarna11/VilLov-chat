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
    let visibility: MessageVisibility
}

@MainActor
final class LocalMessageStore {
    private let encryptedStore: EncryptedFileStore

    init(encryptedStore: EncryptedFileStore? = nil) {
        self.encryptedStore = encryptedStore ?? EncryptedFileStore()
    }

    func loadMessages(for conversationID: UUID, currentUserID: String) -> [Message] {
        loadMessagesIncludingHidden(for: conversationID, currentUserID: currentUserID)
            .filter { $0.visibility == .visible }
    }

    func saveMessages(_ messages: [Message], for conversationID: UUID, currentUserID: String) {
        let stored = messages.map {
            StoredConversationMessage(
                id: $0.id,
                conversationID: conversationID,
                text: $0.text,
                isIncoming: $0.isIncoming,
                timestamp: $0.timestamp,
                status: $0.status,
                visibility: $0.visibility
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
        var existing = loadMessagesIncludingHidden(for: conversationID, currentUserID: currentUserID)

        for newMessage in newMessages {
            guard !existing.contains(where: { $0.id == newMessage.id }) else { continue }
            existing.append(newMessage)
        }

        existing.sort { $0.timestamp < $1.timestamp }
        saveMessages(existing, for: conversationID, currentUserID: currentUserID)
        return existing.filter { $0.visibility == .visible }
    }

    func appendMessage(
        _ message: Message,
        for conversationID: UUID,
        currentUserID: String
    ) -> [Message] {
        var existing = loadMessagesIncludingHidden(for: conversationID, currentUserID: currentUserID)
        existing.append(message)
        existing.sort { $0.timestamp < $1.timestamp }
        saveMessages(existing, for: conversationID, currentUserID: currentUserID)
        return existing.filter { $0.visibility == .visible }
    }

    func replaceMessage(
        _ message: Message,
        for conversationID: UUID,
        currentUserID: String
    ) -> [Message] {
        var existing = loadMessagesIncludingHidden(for: conversationID, currentUserID: currentUserID)

        if let index = existing.firstIndex(where: { $0.id == message.id }) {
            existing[index] = message
        } else {
            existing.append(message)
        }

        existing.sort { $0.timestamp < $1.timestamp }
        saveMessages(existing, for: conversationID, currentUserID: currentUserID)
        return existing.filter { $0.visibility == .visible }
    }

    func hideMessage(
        _ id: UUID,
        for conversationID: UUID,
        currentUserID: String
    ) -> [Message] {
        var existing = loadMessagesIncludingHidden(for: conversationID, currentUserID: currentUserID)

        if let index = existing.firstIndex(where: { $0.id == id }) {
            let old = existing[index]
            existing[index] = Message(
                id: old.id,
                text: old.text,
                isIncoming: old.isIncoming,
                timestamp: old.timestamp,
                status: old.status,
                visibility: .hidden
            )
        }

        existing.sort { $0.timestamp < $1.timestamp }
        saveMessages(existing, for: conversationID, currentUserID: currentUserID)
        return existing.filter { $0.visibility == .visible }
    }

    func deleteMessage(
        _ id: UUID,
        for conversationID: UUID,
        currentUserID: String
    ) -> [Message] {
        var existing = loadMessagesIncludingHidden(for: conversationID, currentUserID: currentUserID)
        existing.removeAll { $0.id == id }
        existing.sort { $0.timestamp < $1.timestamp }
        saveMessages(existing, for: conversationID, currentUserID: currentUserID)
        return existing.filter { $0.visibility == .visible }
    }

    private func loadMessagesIncludingHidden(for conversationID: UUID, currentUserID: String) -> [Message] {
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
                        status: $0.status,
                        visibility: $0.visibility
                    )
                }
                .sorted { $0.timestamp < $1.timestamp }
        } catch {
            return []
        }
    }

    private func storagePath(for conversationID: UUID, currentUserID: String) -> String {
        "messages/\(currentUserID)_\(conversationID.uuidString).json.enc"
    }
}
