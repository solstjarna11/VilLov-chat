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
    private let defaults: UserDefaults
    private let storageKeyPrefix = "conversation_messages_"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadMessages(for conversationID: UUID, currentUserID: String) -> [Message] {
        let key = storageKey(for: conversationID, currentUserID: currentUserID)

        guard let data = defaults.data(forKey: key) else {
            return []
        }

        do {
            let stored = try JSONDecoder().decode([StoredConversationMessage].self, from: data)
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
            let data = try JSONEncoder().encode(stored)
            defaults.set(data, forKey: storageKey(for: conversationID, currentUserID: currentUserID))
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

    private func storageKey(for conversationID: UUID, currentUserID: String) -> String {
        storageKeyPrefix + currentUserID + "_" + conversationID.uuidString
    }
}
