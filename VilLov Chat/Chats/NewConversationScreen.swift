//
//  NewConversationScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct NewConversationScreen: View {
    @StateObject private var viewModel: NewConversationViewModel
    
    init() {
            _viewModel = StateObject(wrappedValue: NewConversationViewModel())
        }

        init(viewModel: NewConversationViewModel) {
            _viewModel = StateObject(wrappedValue: viewModel)
        }

    var body: some View {
        List {
            if viewModel.hasResults {
                if !viewModel.verifiedContacts.isEmpty {
                    Section("Verified") {
                        ForEach(viewModel.verifiedContacts) { contact in
                            contactNavigationLink(for: contact)
                        }
                    }
                }

                if !viewModel.otherContacts.isEmpty {
                    Section("Other Contacts") {
                        ForEach(viewModel.otherContacts) { contact in
                            contactNavigationLink(for: contact)
                        }
                    }
                }
            }
        }
        .navigationTitle("New Conversation")
        .searchable(text: $viewModel.searchText, prompt: "Search contacts")
        .overlay {
            if !viewModel.hasResults {
                ContentUnavailableView(
                    "No Contacts Found",
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text("Try searching with a different name.")
                )
            }
        }
    }

    @ViewBuilder
    private func contactNavigationLink(for contact: Contact) -> some View {
        NavigationLink {
            ChatScreen(conversation: viewModel.makeConversation(from: contact))
        } label: {
            ContactRow(contact: contact)
        }
    }
}

#Preview {
    NavigationStack {
        NewConversationScreen(
            viewModel: NewConversationViewModel(
                provider: MockDataProvider()
            )
        )
    }
}
