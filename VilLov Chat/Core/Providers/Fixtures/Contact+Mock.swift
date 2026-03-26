//
//  Contact+Mock.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

extension Contact {
    static let mockData: [Contact] = [
        Contact(id: UUID(), name: "Alice Johnson", trustState: .verified),
        Contact(id: UUID(), name: "Bob Smith", trustState: .unverified),
        Contact(id: UUID(), name: "Charlie Team", trustState: .verified)
    ]
}
