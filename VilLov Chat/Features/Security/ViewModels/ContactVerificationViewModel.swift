//
//  ContactVerificationViewModel.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//

import Foundation
import Observation

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

@MainActor
@Observable
final class ContactVerificationViewModel {
    let conversation: Conversation
    let verificationData: ContactVerificationViewData

    init(
        conversation: Conversation,
        verificationData: ContactVerificationViewData
    ) {
        self.conversation = conversation
        self.verificationData = verificationData
    }

    var statusTitle: String {
        verificationData.isVerified ? "This contact is verified" : "This contact is not verified"
    }

    var statusSystemImage: String {
        verificationData.isVerified ? "checkmark.shield.fill" : "exclamationmark.shield"
    }

    var safetyNumber: String {
        verificationData.safetyNumber
    }

    var qrCodeDescription: String {
        verificationData.qrCodeDescription
    }

    func copySafetyNumberToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = verificationData.safetyNumber
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(verificationData.safetyNumber, forType: .string)
        #endif
    }
}
