//
//  Contact+Mock.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

extension Contact {
    static let mockAlice = Contact(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        name: "Alice Johnson",
        trustState: .verified,
        userID: "user_alice"
    )

    static let mockBob = Contact(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        name: "Bob Smith",
        trustState: .unverified,
        userID: "user_bob"
    )

    static let mockCharlie = Contact(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        name: "Charlie Brown",
        trustState: .verified,
        userID: "user_charlie"
    )

    static let mockData: [Contact] = [
        .mockAlice,
        .mockBob,
        .mockCharlie
    ]
}
