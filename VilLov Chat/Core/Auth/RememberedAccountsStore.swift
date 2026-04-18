//
//  RememberedAccountsStore.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 17.4.2026.
//


import Foundation

@MainActor
final class RememberedAccountsStore {
    private let defaults: UserDefaults
    private let storageKey = "remembered_accounts"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadAccounts() -> [RememberedAccount] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }

        do {
            let accounts = try JSONDecoder().decode([RememberedAccount].self, from: data)
            return accounts.sorted { $0.lastUsedAt > $1.lastUsedAt }
        } catch {
            return []
        }
    }

    func mostRecentAccount() -> RememberedAccount? {
        loadAccounts().first
    }

    func upsertAccount(userHandle: String, displayName: String) {
        let normalizedUserHandle = userHandle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedUserHandle.isEmpty else { return }

        var accounts = loadAccounts()
        accounts.removeAll { $0.userHandle == normalizedUserHandle }
        accounts.insert(
            RememberedAccount(
                userHandle: normalizedUserHandle,
                displayName: normalizedDisplayName.isEmpty ? normalizedUserHandle : normalizedDisplayName,
                lastUsedAt: Date()
            ),
            at: 0
        )

        saveAccounts(accounts)
    }

    private func saveAccounts(_ accounts: [RememberedAccount]) {
        do {
            let data = try JSONEncoder().encode(accounts)
            defaults.set(data, forKey: storageKey)
        } catch {
            return
        }
    }
}