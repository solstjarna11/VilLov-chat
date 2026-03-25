//
//  LinkedDevicesScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct LinkedDevicesScreen: View {
    @State private var devices: [Device] = Device.mockData

    private var currentDevice: Device? {
        devices.first(where: { $0.isCurrentDevice })
    }

    private var linkedDevices: [Device] {
        devices.filter { !$0.isCurrentDevice }
    }

    var body: some View {
        NavigationStack {
            List {
                if let currentDevice {
                    Section("Current Device") {
                        DeviceRow(device: currentDevice)
                    }
                }

                Section("Linked Devices") {
                    if linkedDevices.isEmpty {
                        Text("No additional linked devices.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(linkedDevices) { device in
                            HStack {
                                DeviceRow(device: device)

                                Spacer()

                                Button(role: .destructive) {
                                    removeLinkedDevice(device)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .onDelete(perform: removeLinkedDevices)
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

    private func removeLinkedDevices(at offsets: IndexSet) {
        let removableDevices = linkedDevices
        let idsToRemove = offsets.map { removableDevices[$0].id }
        devices.removeAll { idsToRemove.contains($0.id) }
    }
    private func removeLinkedDevice(_ device: Device) {
        devices.removeAll { $0.id == device.id }
    }
}
