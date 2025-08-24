//
//  PricingServicesFactory.swift
//
//
//  Created by Isaac Iniongun on 10/05/2024.
//

import Foundation

final class PricingServicesFactory {
    static let shared = PricingServicesFactory()
    private let preference: PreferenceProtocol
    
    private init(preference: PreferenceProtocol = PreferenceImpl()) {
        self.preference = preference
    }
    
    private var canVerify: Bool {
        preference.DJAuthStep.config?.verification == true
    }
    
    func services(
        governmentIDType: DJGovernmentIDType? = nil,
        verificationMethod: GovtIDVerificationMethod? = nil
    ) -> [String] {
        guard let pageName = preference.DJAuthStep.name, let pricingConfig = preference.DJPricingServicesConfig else { return [] }
        switch pageName {
        case .countries, .index, .additionalDocument, .signature, .userData, .idOptions:
            return []
        case .phoneNumber:
            if canVerify {
                return [pricingConfig.phoneNumber.verification.orEmpty]
            }
            
        case .address:
            if canVerify {
                return [pricingConfig.address.verification.orEmpty]
            }
        case .email:
            if canVerify {
                return [pricingConfig.email.verification.orEmpty]
            }
        case .governmentData:
            return governmentDataServices(idType: governmentIDType)
        case .governmentDataVerification, .selfie:
            return governmentDataVerificationServices(method: verificationMethod)
        case .businessData:
            return [pricingConfig.businessData.cac.orEmpty]
        case .id:
            return [pricingConfig.id.idDefault.orEmpty]
        case .businessID:
            return [pricingConfig.businessID.idDefault.orEmpty]
        }
        return []
    }
    
    private func governmentDataServices(idType: DJGovernmentIDType?) -> [String] {
        guard let idType, let config = preference.DJPricingServicesConfig?.governmentData else { return [] }
        switch idType {
        case .bvn:
            return [config.bvn.orEmpty]
        case .nin:
            return [config.nin.orEmpty]
        case .vnin:
            return [config.vnin.orEmpty]
        case .dl:
            return [config.dl.orEmpty]
        case .mobile:
            return [config.mobile.orEmpty]
        case .ghDL:
            return [config.ghDL.orEmpty]
        case .ghVotersCard:
            return [config.ghVoter.orEmpty]
        case .keDL:
            return [config.keDL.orEmpty]
        case .keID:
            return [config.keID.orEmpty]
        case .keKRA:
            return [config.keKra.orEmpty]
        case .aoNin:
            return [config.aoNin.orEmpty]
        case .zaId:
            return [config.zaID.orEmpty]
        case .bvnAdvance:
            return [config.bvnAdvance.orEmpty]
        default:
            return []
        }
    }
    
    private func governmentDataVerificationServices(method: GovtIDVerificationMethod?) -> [String] {
        guard let method, let config = preference.DJPricingServicesConfig?.governmentDataVerification else { return [] }
        switch method {
        case .govtID:
            return []
        case .selfie:
            return [config.selfie.orEmpty]
        case .phoneNumberOTP:
            return [config.otp.orEmpty]
        case .emailOTP:
            return [config.emailOtp.orEmpty]
        case .selfieVideo:
            return [config.video.orEmpty]
        case .whatsappOtp:
            return [config.whatsappOtp.orEmpty]
        }
    }
    
}
