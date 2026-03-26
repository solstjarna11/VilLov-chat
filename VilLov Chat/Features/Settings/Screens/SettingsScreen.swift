import SwiftUI

struct SettingsScreen: View {
    @StateObject private var viewModel: SettingsViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: SettingsViewModel())
    }
    init(viewModel: SettingsViewModel){
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                accountSection
                securitySection
                privacySection
                notificationsSection
                storageSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var accountSection: some View {
        Section("Account") {
            SettingsRow(title: "Profile", systemImage: "person.circle", detail: "Lovisa")
            SettingsRow(title: "Username", systemImage: "at", detail: "@lovisa")
        }
    }

    private var securitySection: some View {
        Section("Security") {
            NavigationLink {
                LinkedDevicesScreen()
            } label: {
                SettingsRow(title: "Linked Devices", systemImage: "desktopcomputer")
            }

            NavigationLink {
                SecurityOverviewPlaceholderScreen()
            } label: {
                SettingsRow(title: "Security Overview", systemImage: "checkmark.shield")
            }

            Toggle("Use Biometrics / Device Unlock", isOn: $viewModel.biometricsEnabled)
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Toggle("Read Receipts", isOn: $viewModel.readReceiptsEnabled)
            Toggle("Link Previews", isOn: $viewModel.linkPreviewsEnabled)

            NavigationLink {
                RecoveryPlaceholderScreen()
            } label: {
                SettingsRow(title: "Recovery Options", systemImage: "key")
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
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
}

#Preview {
    SettingsScreen()
}
