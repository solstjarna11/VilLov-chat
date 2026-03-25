//
//  Contact+Mock.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

extension Contact {
    static let mockData: [Contact] = [
        Contact(id: UUID(), name: "Alice Johnson", isVerified: true),
        Contact(id: UUID(), name: "Bob Smith", isVerified: false),
        Contact(id: UUID(), name: "Charlie Team", isVerified: true)
    ]
}
