//
//  ConversationListViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation
import Observation

@MainActor
@Observable
final class ConversationListViewModel {
    var searchText = ""
    private(set) var conversations: [Conversation]

    private let provider: ConversationProviding

    init(provider: ConversationProviding) {
        self.provider = provider
        self.conversations = provider.loadConversations()
    }

    var filteredConversations: [Conversation] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearchText.isEmpty else {
            return conversations
        }

        return conversations.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedSearchText) ||
            $0.lastMessagePreview.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    var hasResults: Bool {
        !filteredConversations.isEmpty
    }

    func addConversation(_ conversation: Conversation) {
        conversations.insert(conversation, at: 0)
    }
}
