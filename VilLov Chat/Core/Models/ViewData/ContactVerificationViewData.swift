//
//  ContactVerificationViewData.swift
//  VilLov Chat
//
//  Created by Lovísa Sól on 25.3.2026.
//


import Foundation

struct ContactVerificationViewData: Hashable {
    let isVerified: Bool
    let safetyNumber: String
    let qrCodeDescription: String
}