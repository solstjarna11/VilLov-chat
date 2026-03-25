//
//  ConversationListViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation
import SwiftUI
import Combine

@MainActor
final class ConversationListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var conversations: [Conversation]

    init(conversations: [Conversation]? = nil) {
        self.conversations = conversations ?? Conversation.mockData
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
