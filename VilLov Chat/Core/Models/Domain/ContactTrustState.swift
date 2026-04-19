//
//  ContactTrustState.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation

enum ContactTrustState: String, Codable, CaseIterable, Hashable {
    case verified
    case unverified
    case changed
}
