//
//  SettingsRow.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import SwiftUI

struct SettingsRow: View {
    let title: String
    let systemImage: String
    var detail: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 20)

            Text(title)

            Spacer()

            if let detail {
                Text(detail)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}