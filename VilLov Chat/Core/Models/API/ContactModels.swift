//
//  APIContact.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 12.4.2026.
//


import Foundation

struct APIContact: Codable, Hashable {
    let userID: String
    let displayName: String
}