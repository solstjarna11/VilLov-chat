//
//  MainTabView.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import SwiftUI

struct MainTabView: View {
    let environment: AppEnvironment
    let currentUserID: String

    var body: some View {
        TabView {
            ConversationListScreen(
                viewModel: ConversationListViewModel(
                    contactService: environment.contactService,
                    conversationDirectoryService: environment.conversationDirectoryService,
                    currentUserID: currentUserID,
                    identityTrustStore: environment.identityTrustStore
                ),
                messageProvider: environment.providers.messages,
                contactService: environment.contactService,
                conversationService: environment.conversationService,
                identityTrustStore: environment.identityTrustStore,
                localKeyStore: environment.localKeyStore
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
                viewModel: SettingsViewModel(
                    currentUserID: currentUserID,
                    rememberedAccountName: environment.session.rememberedAccountName
                ),
                deviceProvider: environment.providers.devices,
                onSignOut: {
                    environment.authService.signOut()
                    environment.session.signOut()
                }
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
