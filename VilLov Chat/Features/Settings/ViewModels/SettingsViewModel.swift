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

    init(
        notificationsEnabled: Bool = true,
        biometricsEnabled: Bool = true,
        linkPreviewsEnabled: Bool = false,
        readReceiptsEnabled: Bool = true
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.biometricsEnabled = biometricsEnabled
        self.linkPreviewsEnabled = linkPreviewsEnabled
        self.readReceiptsEnabled = readReceiptsEnabled
    }
}
