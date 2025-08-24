//
//  DJGovernmentIDConfig.swift
//
//
//  Created by Isaac Iniongun on 12/12/2023.
//

import Foundation

// MARK: - GovernmentIDConfig
struct DJGovernmentIDConfig: Codable {
    let bvn, nin, vnin, dl: DJGovernmentID?
    let passport, national, permit, custom: DJGovernmentID?
    let voter: DJGovernmentID?
    let mobile: DJGovernmentID?
    let ngDLI, ngPass, ngNat, ukRP: DJGovernmentID?
    let ngCustom, ngVcard, ngNINSlip: DJGovernmentID?
    let selfie, selfieVideo, otp: DJGovernmentID?
    let whatsappOtp: DJGovernmentID?
    let ghDL, ghVoter, tzNIN, ugID: DJGovernmentID?
    let ugTelco, keDL, keID, keKRA: DJGovernmentID?
    let saDL, saID: DJGovernmentID?
    let cac: DJGovernmentID?
    let tin: DJGovernmentID?

    enum CodingKeys: String, CodingKey {
        case bvn, nin, vnin, dl, passport, national, permit, custom, voter, mobile
        case ngDLI = "NG-DLI"
        case ngPass = "NG-PASS"
        case ngNat = "NG-NAT"
        case ukRP = "UK-RP"
        case ngCustom = "NG-CUSTOM"
        case ngVcard = "NG-VCARD"
        case ngNINSlip = "NG-NIN-SLIP"
        case selfie, otp
        case whatsappOtp
        case selfieVideo = "selfie-video"
        case ghDL = "gh-dl"
        case ghVoter = "gh-voter"
        case tzNIN = "tz-nin"
        case ugID = "ug-id"
        case ugTelco = "ug-telco"
        case keDL = "ke-dl"
        case keID = "ke-id"
        case keKRA = "ke-kra"
        case saDL = "sa-dl"
        case saID = "sa-id"
        case cac, tin
    }
}
