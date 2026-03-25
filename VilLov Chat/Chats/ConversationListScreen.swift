//
//  ConversationListScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct ConversationListScreen: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Conversations will appear here")
            }
            .navigationTitle("Chats")
        }
    }
}
