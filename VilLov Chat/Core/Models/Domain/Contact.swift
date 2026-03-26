//
//  Contact.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

struct Contact: Identifiable, Equatable {
    let id: UUID
    let name: String
    let trustState: ContactTrustState
    let userID: String?

    init(
        id: UUID,
        name: String,
        trustState: ContactTrustState,
        userID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.trustState = trustState
        self.userID = userID
    }
}
