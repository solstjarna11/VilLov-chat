//
//  SecurityStatusBanner.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct SecurityStatusBanner: View {
    let isVerified: Bool
    let disappearingMessagesEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                isVerified ? "Identity verified" : "Identity not verified",
                systemImage: isVerified ? "checkmark.shield.fill" : "exclamationmark.shield"
            )
            .font(.headline)

            if disappearingMessagesEnabled {
                Label("Disappearing messages enabled", systemImage: "timer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}
