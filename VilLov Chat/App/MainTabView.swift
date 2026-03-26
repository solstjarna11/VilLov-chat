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
                    provider: environment.providers.conversations
                ),
                messageProvider: environment.providers.messages,
                contactProvider: environment.providers.contacts,
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
