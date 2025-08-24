//
//  GovtIDVerificationMethod.swift
//
//
//  Created by Isaac Iniongun on 28/10/2023.
//

import UIKit

enum GovtIDVerificationMethod: String, CaseIterable, SelectableItem {
    case govtID, selfie, whatsappOtp, phoneNumberOTP, emailOTP, selfieVideo

    var title: String {
        switch self {
        case .selfie:
            return "Selfie"
        case .whatsappOtp: 
            return "WhatsApp"

        case .phoneNumberOTP:
            return "Phone Number OTP"
        case .emailOTP:
            return "Email OTP"
        case .selfieVideo:
            return "Video KYC"
        case .govtID:
            return "Govt. ID"
        }
    }

    var kycText: String {
        switch self {
        case .selfie:
            return "Capture"
        case .phoneNumberOTP, .emailOTP, .govtID:
            return ""
        case .selfieVideo:
            return "Record"
        case .whatsappOtp:
            return "WhatsApp"
        }
    }

    var iconConfig: IconConfig { .init() }
}

extension [GovtIDVerificationMethod] {
    var titles: [String] {
        map { $0.title }
    }
}
