//
//  SecurityOverviewPlaceholderScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import SwiftUI

struct SecurityOverviewPlaceholderScreen: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 48))

            Text("Security Overview")
                .font(.title2)
                .fontWeight(.semibold)

            Text("This screen will provide a summary of device security, verification, and session health.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Security Overview")
    }
}