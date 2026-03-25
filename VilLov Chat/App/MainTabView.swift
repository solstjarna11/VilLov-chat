//
//  MainTabView.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ConversationListScreen()
                .tabItem {
                    Label("Chats", systemImage: "message")
                }

            LinkedDevicesScreen()
                .tabItem {
                    Label("Devices", systemImage: "desktopcomputer")
                }

            SettingsScreen()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
