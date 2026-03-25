//
//  LinkedDevicesScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct LinkedDevicesScreen: View {
    @StateObject private var viewModel = LinkedDevicesViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let currentDevice = viewModel.currentDevice {
                    Section("Current Device") {
                        DeviceRow(device: currentDevice)
                    }
                }

                Section("Linked Devices") {
                    if !viewModel.hasLinkedDevices {
                        Text("No additional linked devices.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.linkedDevices) { device in
                            HStack {
                                DeviceRow(device: device)

                                Spacer()

                                Button(role: .destructive) {
                                    viewModel.removeLinkedDevice(device)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .onDelete(perform: viewModel.removeLinkedDevices)
                    }
                }

                Section("Device Actions") {
                    Button {
                        // connect to real link-device flow later
                    } label: {
                        Label("Link New Device", systemImage: "plus.circle")
                    }

                    Button(role: .destructive) {
                        // connect to real remove-all-other-devices flow later
                    } label: {
                        Label("Remove All Other Devices", systemImage: "trash")
                    }
                }

                Section("About Device Linking") {
                    Text("Linked devices allow secure access to your conversations from more than one trusted device.")
                    Text("Only devices you explicitly authorize should remain linked to your account.")
                }
                .foregroundStyle(.secondary)
            }
            .navigationTitle("Devices")
        }
    }
}

#Preview {
    LinkedDevicesScreen()
}
