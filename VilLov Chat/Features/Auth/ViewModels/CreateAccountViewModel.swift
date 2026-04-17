//
//  CreateAccountViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 17.4.2026.
//


//
//  CreateAccountViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 17.4.2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class CreateAccountViewModel {
    var userHandle = ""
    var displayName = ""
    var errorMessage: String?

    var trimmedUserHandle: String {
        userHandle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canContinue: Bool {
        validationError == nil
    }

    var validationError: String? {
        if trimmedUserHandle.isEmpty {
            return "Enter a username."
        }

        if trimmedDisplayName.isEmpty {
            return "Enter a display name."
        }

        if !isValidUserHandle(trimmedUserHandle) {
            return "Username can only contain lowercase letters, numbers, and underscores."
        }

        return nil
    }

    var normalizedUserHandle: String {
        trimmedUserHandle.lowercased()
    }

    private func isValidUserHandle(_ value: String) -> Bool {
        let pattern = "^[a-z0-9_]+$"
        return value.range(of: pattern, options: .regularExpression) != nil
    }
}