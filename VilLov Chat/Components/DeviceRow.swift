//
//  DeviceRow.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import SwiftUI

struct DeviceRow: View {
    let device: Device

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(device.name)
                        .font(.headline)

                    if device.isCurrentDevice {
                        Text("Current")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(.quaternary))
                    }
                }

                Text(device.platform)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Last seen \(device.lastSeen.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var iconName: String {
        switch device.platform.lowercased() {
        case let value where value.contains("iphone"):
            return "iphone"
        case let value where value.contains("ipad"):
            return "ipad"
        case let value where value.contains("mac"):
            return "laptopcomputer"
        default:
            return "desktopcomputer"
        }
    }
}