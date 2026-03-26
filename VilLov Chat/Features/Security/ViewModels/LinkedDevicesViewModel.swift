//
//  LinkedDevicesViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation
import Observation

@MainActor
@Observable
final class LinkedDevicesViewModel {
    private(set) var devices: [Device]

    private let provider: DeviceProviding

    init(provider: DeviceProviding) {
        self.provider = provider
        self.devices = provider.loadDevices()
    }

    var currentDevice: Device? {
        devices.first(where: { $0.isCurrentDevice })
    }

    var linkedDevices: [Device] {
        devices.filter { !$0.isCurrentDevice }
    }

    var hasLinkedDevices: Bool {
        !linkedDevices.isEmpty
    }

    func removeLinkedDevices(at offsets: IndexSet) {
        let removableDevices = linkedDevices
        let idsToRemove = offsets.map { removableDevices[$0].id }
        devices.removeAll { idsToRemove.contains($0.id) }
    }

    func removeLinkedDevice(_ device: Device) {
        devices.removeAll { $0.id == device.id }
    }
}
