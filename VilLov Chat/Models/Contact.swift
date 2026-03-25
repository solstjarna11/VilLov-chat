//
//  Contact.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

struct Contact: Identifiable, Hashable {
    let id: UUID
    let name: String
    let isVerified: Bool
}