//
//  DJGovernmentID.swift
//
//
//  Created by Isaac Iniongun on 12/12/2023.
//

import Foundation

struct DJGovernmentID: Codable {
    let name, abbr: String?
    let subtext: String?
    let subtext2: String?
    let placeholder, idEnum: String?
    let spanid: String?
    let inputType, inputMode: DJInputMode?
    let minLength, maxLength, id, value: String?
    let idName: String?

    enum CodingKeys: String, CodingKey {
        case name, abbr, subtext, subtext2, placeholder
        case idEnum = "enum"
        case spanid, inputType, inputMode, minLength, maxLength, id, value, idName
    }
    
    var verificationModeParam: String? {
        guard let name else { return nil }
        if name.insensitiveContains("sms") {
            return "OTP"
        } else if name.insensitiveContains("selfie") {
            return "LIVENESS"
        } else if name.insensitiveContains("whatsapp") {
            return "Whatsapp"
        }
        else {
            return nil
        }
    }
    
    var idTypeParam: String {
        idEnum ?? value ?? name ?? ""
    }
    
    var idType: DJGovernmentIDType? {
        DJGovernmentIDType(rawValue: value ?? "")
    }
    
    var verificationMethod: GovtIDVerificationMethod? {
        switch name?.lowercased() {
        case "otp":
            return .phoneNumberOTP
        case "selfie":
            return .selfie
        case "selfie-video":
            return .selfieVideo
        
        case "whatsappotp":
            return .whatsappOtp
        default:
            return nil
        }
    }
    
}

extension [DJGovernmentID] {
    var names: [String] { compactMap { $0.name } }
    var symbols: [String] { compactMap { $0.idEnum?.lowercased() } }
}

extension DJGovernmentID {
    static let empty = DJGovernmentID(
        name: nil,
        abbr: nil,
        subtext: nil,
        subtext2: nil,
        placeholder: nil,
        idEnum: nil,
        spanid: nil,
        inputType: nil,
        inputMode: nil,
        minLength: nil,
        maxLength: nil,
        id: nil,
        value: nil,
        idName: nil
    )
}
