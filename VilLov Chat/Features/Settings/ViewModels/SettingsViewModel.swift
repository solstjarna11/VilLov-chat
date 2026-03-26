//
//  SettingsViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var notificationsEnabled: Bool
    @Published var biometricsEnabled: Bool
    @Published var linkPreviewsEnabled: Bool
    @Published var readReceiptsEnabled: Bool

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
