//
//  LinkedDevicesScreen.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct LinkedDevicesScreen: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Linked Devices")
                    .font(.title2)
                Text("Link a new device or manage existing sessions.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("Devices")
        }
    }
}

