//
//  SettingsScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    Button("Profile") {}
                    Button("Sign Out") {}
                }
                Section("Privacy") {
                    Button("Blocked Contacts") {}
                    Button("Data & Storage") {}
                }
                Section("About") {
                    Button("Licenses") {}
                    Button("Version") {}
                }
            }
            .navigationTitle("Settings")
        }
    }
}
