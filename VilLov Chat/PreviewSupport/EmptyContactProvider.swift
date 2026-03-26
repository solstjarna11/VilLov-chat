//
//  EmptyContactProvider.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 26.3.2026.
//


import Foundation

struct EmptyContactProvider: ContactProviding {
    func loadContacts(for currentUserID: String?) -> [Contact] {
        []
    }
}

struct PopulatedContactProvider: ContactProviding {
    func loadContacts(for currentUserID: String?) -> [Contact] {
        switch currentUserID {
        case "user_alice":
            return [
                .mockBob,
                .mockCharlie
            ]
        case "user_bob":
            return [
                .mockAlice
            ]
        case "user_charlie":
            return [
                .mockAlice
            ]
        default:
            return Contact.mockData
        }
    }
}
