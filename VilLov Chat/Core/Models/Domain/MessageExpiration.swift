//
//  MessageExpiration.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

enum MessageExpiration: String, CaseIterable, Identifiable {
    case thirtyMinutes
    case oneHour
    case oneDay
    case oneWeek

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thirtyMinutes:
            return "30 Minutes"
        case .oneHour:
            return "1 Hour"
        case .oneDay:
            return "1 Day"
        case .oneWeek:
            return "1 Week"
        }
    }
}