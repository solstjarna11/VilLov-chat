//
//  SettingsScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI
import Observation

struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel

    private let deviceProvider: DeviceProviding
    private let onSignOut: () -> Void

    init(
        viewModel: SettingsViewModel,
        deviceProvider: DeviceProviding,
        onSignOut: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.deviceProvider = deviceProvider
        self.onSignOut = onSignOut
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        NavigationStack {
            List {
                accountSection
                securitySection(viewModel: $bindableViewModel)
                privacySection(viewModel: $bindableViewModel)
                notificationsSection(viewModel: $bindableViewModel)
                storageSection
                aboutSection
                signOutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var accountSection: some View {
        Section("Account") {
            SettingsRow(
                title: "Profile",
                systemImage: "person.circle",
                detail: viewModel.profileDisplayName
            )

            SettingsRow(
                title: "Username",
                systemImage: "at",
                detail: viewModel.usernameDisplay
            )
        }
    }

    private func securitySection(viewModel: Bindable<SettingsViewModel>) -> some View {
        Section("Security") {
            NavigationLink {
                LinkedDevicesScreen(
                    viewModel: LinkedDevicesViewModel(
                        provider: deviceProvider
                    )
                )
            } label: {
                SettingsRow(title: "Linked Devices", systemImage: "desktopcomputer")
            }

            NavigationLink {
                SecurityOverviewPlaceholderScreen()
            } label: {
                SettingsRow(title: "Security Overview", systemImage: "checkmark.shield")
            }

            Toggle("Use Biometrics / Device Unlock", isOn: viewModel.biometricsEnabled)
        }
    }

    private func privacySection(viewModel: Bindable<SettingsViewModel>) -> some View {
        Section("Privacy") {
            Toggle("Read Receipts", isOn: viewModel.readReceiptsEnabled)
            Toggle("Link Previews", isOn: viewModel.linkPreviewsEnabled)

            NavigationLink {
                RecoveryPlaceholderScreen()
            } label: {
                SettingsRow(title: "Recovery Options", systemImage: "key")
            }
        }
    }

    private func notificationsSection(viewModel: Bindable<SettingsViewModel>) -> some View {
        Section("Notifications") {
            Toggle("Enable Notifications", isOn: viewModel.notificationsEnabled)
        }
    }

    private var storageSection: some View {
        Section("Storage") {
            SettingsRow(title: "Manage Local Storage", systemImage: "internaldrive")
            SettingsRow(title: "Media Cache", systemImage: "photo.on.rectangle", detail: "128 MB")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            SettingsRow(title: "Version", systemImage: "info.circle", detail: "0.1")
        }
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                onSignOut()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                }
            }
        }
    }
}


