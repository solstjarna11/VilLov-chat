//
//  ContactRow.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import SwiftUI

struct ContactRow: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.quaternary)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(initials)
                        .font(.subheadline.weight(.semibold))
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(contact.name)
                        .font(.body)

                    if contact.isVerified {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var initials: String {
        let parts = contact.name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first }.map(String.init).joined()
    }
}