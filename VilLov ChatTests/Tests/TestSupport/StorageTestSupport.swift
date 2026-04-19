//
//  StorageTestSupport.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 19.4.2026.
//


import Foundation
@testable import VilLov_Chat

enum StorageTestSupport {
    static func makeIsolatedEncryptedStore(testName: String = UUID().uuidString) -> (EncryptedFileStore, LocalStorageKeyManager, String) {
        let suffix = UUID().uuidString
        let service = "com.villovchat.tests.\(testName).\(suffix)"
        let account = "master-key"
        let directory = "EncryptedLocalStoreTests-\(testName)-\(suffix)"

        let keyManager = LocalStorageKeyManager(
            service: service,
            account: account
        )

        let store = EncryptedFileStore(
            keyManager: keyManager,
            directoryName: directory
        )

        return (store, keyManager, directory)
    }

    static func cleanup(
        store: EncryptedFileStore,
        keyManager: LocalStorageKeyManager
    ) {
        try? store.deleteStoreDirectory()
        try? keyManager.deleteMasterKey()
    }
}