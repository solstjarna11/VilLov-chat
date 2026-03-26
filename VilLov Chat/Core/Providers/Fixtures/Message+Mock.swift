//
//  Message+Mock.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

extension Message {
    static let mockMessages: [Message] = [
        Message(
            id: UUID(),
            text: "Hey, did you check the encryption design?",
            isIncoming: true,
            timestamp: Date().addingTimeInterval(-3600),
            status: .read
        ),
        Message(
            id: UUID(),
            text: "Yes, looks solid. We should review key rotation next.",
            isIncoming: false,
            timestamp: Date().addingTimeInterval(-3500),
            status: .read
        ),
        Message(
            id: UUID(),
            text: "Agreed. Also need to verify device linking flow.",
            isIncoming: true,
            timestamp: Date().addingTimeInterval(-3400),
            status: .delivered
        )
    ]
}
