//
//  RememberedAccount.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 17.4.2026.
//

import Foundation

struct RememberedAccount: Codable, Identifiable, Equatable, Hashable {
    let userHandle: String
    let displayName: String
    let lastUsedAt: Date

    var id: String { userHandle }
}
