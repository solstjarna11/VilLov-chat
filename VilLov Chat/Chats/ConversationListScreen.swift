//
//  ConversationListScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct ConversationListScreen: View {
    @State private var searchText = ""
    @State private var conversations: [Conversation] = Conversation.mockData

    private var filteredConversations: [Conversation] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return conversations
        }

        return conversations.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.lastMessagePreview.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredConversations) { conversation in
                NavigationLink {
                    ChatScreen(conversation: conversation)
                } label: {
                    ConversationRow(conversation: conversation)
                }
            }
            .listStyle(.inset)
            .navigationTitle("Chats")
            .searchable(text: $searchText, prompt: "Search conversations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // connect to new conversation flow later
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New Conversation")
                }
            }
            .overlay {
                if filteredConversations.isEmpty {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "message",
                        description: Text("Start a new secure conversation to begin messaging.")
                    )
                }
            }
        }
    }
}
