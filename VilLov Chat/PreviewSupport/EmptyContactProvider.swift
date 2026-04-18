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

