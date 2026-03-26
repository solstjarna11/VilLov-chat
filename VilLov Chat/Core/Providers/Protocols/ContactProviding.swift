//
//  ContactProviding.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

protocol ContactProviding {
    func loadContacts(for currentUserID: String?) -> [Contact]
}
