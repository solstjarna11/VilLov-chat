//
//  Device+Mock.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

extension Device {
    static let mockData: [Device] = [
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
            name: "Lovisa's iPad",
            platform: "iPad",
            lastSeen: Date().addingTimeInterval(-7200),
            isCurrentDevice: false
        )
    ]
}
