//
//  VerificationBadge.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import SwiftUI

struct VerificationBadge: View {
    let isVerified: Bool

    var body: some View {
        Image(systemName: isVerified ? "checkmark.shield.fill" : "exclamationmark.shield")
            .accessibilityLabel(isVerified ? "Verified" : "Not Verified")
    }
}
