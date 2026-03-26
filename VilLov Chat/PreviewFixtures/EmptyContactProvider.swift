//
//  EmptyContactProvider.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct EmptyContactProvider: ContactProviding {
    func loadContacts() -> [Contact] {
        []
    }
}

struct PopulatedContactProvider: ContactProviding {
    func loadContacts() -> [Contact] {
        [
            Contact(id: UUID(), name: "Alice Johnson", trustState: .verified),
            Contact(id: UUID(), name: "Bob Smith", trustState: .unverified),
            Contact(id: UUID(), name: "Charlie Team", trustState: .verified),
            Contact(id: UUID(), name: "David Lee", trustState: .unverified),
        ]
    }
}
