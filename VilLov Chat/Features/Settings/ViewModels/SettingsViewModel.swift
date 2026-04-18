//
//  SettingsViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    var notificationsEnabled: Bool
    var biometricsEnabled: Bool
    var linkPreviewsEnabled: Bool
    var readReceiptsEnabled: Bool

    let currentUserID: String?
    let rememberedAccountName: String?

    init(
        currentUserID: String? = nil,
        rememberedAccountName: String? = nil,
        notificationsEnabled: Bool = true,
        biometricsEnabled: Bool = true,
        linkPreviewsEnabled: Bool = false,
        readReceiptsEnabled: Bool = true
    ) {
        self.currentUserID = currentUserID
        self.rememberedAccountName = rememberedAccountName
        self.notificationsEnabled = notificationsEnabled
        self.biometricsEnabled = biometricsEnabled
        self.linkPreviewsEnabled = linkPreviewsEnabled
        self.readReceiptsEnabled = readReceiptsEnabled
    }

    var profileDisplayName: String {
        rememberedAccountName ?? fallbackDisplayName(for: currentUserID) ?? "Unknown"
    }

    var usernameDisplay: String {
        if let currentUserID, !currentUserID.isEmpty {
            return "@\(currentUserID)"
        }
        return "@unknown"
    }

    private func fallbackDisplayName(for userID: String?) -> String? {
        switch userID {
        case "user_alice":
            return "Alice"
        case "user_bob":
            return "Bob"
        case "user_charlie":
            return "Charlie"
        default:
            return nil
        }
    }
}
