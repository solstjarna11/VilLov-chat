//
//  MainTabView.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct MainTabView: View {
    let environment: AppEnvironment

    var body: some View {
        TabView {
            ConversationListScreen(
                viewModel: ConversationListViewModel(
                    contactService: environment.contactService,
                    conversationDirectoryService: environment.conversationDirectoryService,
                    currentUserID: environment.session.currentUserID ?? "user_alice"
                ),
                messageProvider: environment.providers.messages,
                contactService: environment.contactService,
                conversationService: environment.conversationService
            )
            .tabItem {
                Label("Chats", systemImage: "message")
            }

            LinkedDevicesScreen(
                viewModel: LinkedDevicesViewModel(
                    provider: environment.providers.devices
                )
            )
            .tabItem {
                Label("Devices", systemImage: "iphone")
            }

            SettingsScreen(
                viewModel: SettingsViewModel(),
                deviceProvider: environment.providers.devices
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
