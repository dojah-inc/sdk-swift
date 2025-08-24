//
//  PricingServicesConfig.swift
//
//
//  Created by Isaac Iniongun on 10/05/2024.
//

import Foundation

struct PricingServicesConfig: Codable {
    let aml: PricingDataConfig
    let governmentData: PricingDataConfig
    let governmentDataVerification: PricingDataConfig
    let selfie: PricingDataConfig
    let businessData: PricingDataConfig
    let phoneNumber, address, email: PricingDataConfig
    let businessID, id: PricingDataConfig
    let index, countries, additionalDocument, signature: PricingDataConfig

    enum CodingKeys: String, CodingKey {
        case index, countries, aml
        case governmentData = "government-data"
        case governmentDataVerification = "government-data-verification"
        case selfie
        case businessData = "business-data"
        case phoneNumber = "phone-number"
        case address, email
        case businessID = "business-id"
        case id
        case additionalDocument = "additional-document"
        case signature
    }
}

struct PricingDataConfig: Codable {
    let bvn, bvnAdvance, vnin, nin: String?
    let dl, mobile, ghDL, ghVoter: String?
    let keKra, keID, keDL, aoNin, zaID: String?
    let verification, aml, cac, idDefault: String?
    let selfie, video, otp,whatsappOtp, emailOtp: String?

    enum CodingKeys: String, CodingKey {
        case bvn, bvnAdvance, vnin, nin, dl, mobile
        case ghDL = "gh-dl"
        case ghVoter = "gh-voter"
        case keKra = "ke-kra"
        case keID = "ke-id"
        case keDL = "ke-dl"
        case aoNin = "ao-nin"
        case zaID = "za-id"
        case idDefault = "default"
        case verification, aml, cac
        case whatsappOtp = "whatsapp"
        case selfie, video, otp, emailOtp
    }
}
