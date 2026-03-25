//
//  ConversationListScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct ConversationListScreen: View {
    @StateObject private var viewModel = ConversationListViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.filteredConversations) { conversation in
                NavigationLink {
                    ChatScreen(conversation: conversation)
                } label: {
                    ConversationRow(conversation: conversation)
                }
            }
            .listStyle(.inset)
            .navigationTitle("Chats")
            .searchable(text: $viewModel.searchText, prompt: "Search conversations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        NewConversationScreen()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New Conversation")
                }
            }
            .overlay {
                if !viewModel.hasResults {
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

#Preview {
    ConversationListScreen()
}
