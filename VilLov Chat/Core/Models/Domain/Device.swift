//
//  Device.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

struct Device: Identifiable, Hashable {
    let id: UUID
    let name: String
    let platform: String
    let lastSeen: Date
    let isCurrentDevice: Bool
}
