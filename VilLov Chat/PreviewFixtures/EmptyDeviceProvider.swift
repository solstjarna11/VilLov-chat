//
//  EmptyDeviceProvider.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct EmptyDeviceProvider: DeviceProviding {
    func loadDevices() -> [Device] {
        []
    }
}

struct MultipleDeviceProvider: DeviceProviding {
    func loadDevices() -> [Device] {
        [
            Device(
                id: UUID(),
                name: "Lovisa’s iPhone",
                platform: "iPhone",
                lastSeen: Date(),
                isCurrentDevice: true
            ),
            Device(
                id: UUID(),
                name: "Lovisa’s MacBook",
                platform: "macOS",
                lastSeen: Date().addingTimeInterval(-1800),
                isCurrentDevice: false
            ),
            Device(
                id: UUID(),
                name: "iPad Air",
                platform: "iPad",
                lastSeen: Date().addingTimeInterval(-7200),
                isCurrentDevice: false
            )
        ]
    }
}