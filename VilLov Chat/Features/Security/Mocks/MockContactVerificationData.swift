//
//  MockContactVerificationData.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

enum MockContactVerificationData {
    static let verified = ContactVerificationViewData(
        isVerified: true,
        safetyNumber: """
        48291 19304 55210 88421
        10932 77441 66290 11853
        44019 88274 00192 77351
        """,
        qrCodeDescription: "QR code placeholder for verified contact."
    )

    static let unverified = ContactVerificationViewData(
        isVerified: false,
        safetyNumber: """
        13820 66491 20873 44109
        77420 55318 99021 44862
        11509 22084 63177 50219
        """,
        qrCodeDescription: "QR code placeholder for unverified contact."
    )
}