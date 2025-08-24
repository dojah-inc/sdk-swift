//
//  GovernmentIDFactory.swift
//
//
//  Created by Isaac Iniongun on 01/02/2024.
//

import Foundation

struct GovernmentIDFactory {
    static func getGovernmentIDs(for pageName: DJPageName, preference: PreferenceProtocol) -> [DJGovernmentID] {
        guard let govtDataConfig = preference.DJGovernmentIDConfig,
              let authStep = preference.DJSteps.first(where: { $0.name == pageName })
        else { return [] }
        
        var governmentIDs = [DJGovernmentID]()
        
        if authStep.config?.bvn == true, let bvnConfig = govtDataConfig.bvn {
            governmentIDs.append(bvnConfig)
        }
        
        if authStep.config?.dl == true, let dlConfig = govtDataConfig.dl {
            governmentIDs.append(dlConfig)
        }
        
        if authStep.config?.nin == true, let ninConfig = govtDataConfig.nin {
            governmentIDs.append(ninConfig)
        }
        
        if authStep.config?.vnin == true, let vninConfig = govtDataConfig.vnin {
            governmentIDs.append(vninConfig)
        }
        
        if authStep.config?.passport == true, let passport = govtDataConfig.passport {
            governmentIDs.append(passport)
        }
        
        if authStep.config?.national == true, let national = govtDataConfig.national {
            governmentIDs.append(national)
        }
        
        if authStep.config?.voter == true, let voter = govtDataConfig.voter {
            governmentIDs.append(voter)
        }
        
//        if authStep.config?.ghDL == true, let ghDL = govtDataConfig.ghDL {
//            governmentIDs.append(ghDL)
//        }
//        
        if authStep.config?.ghVoter == true, let ghVoter = govtDataConfig.ghVoter {
            governmentIDs.append(ghVoter)
        }
        
        if authStep.config?.tzNIN == true, let tzNIN = govtDataConfig.tzNIN {
            governmentIDs.append(tzNIN)
        }
        
        if authStep.config?.ugID == true, let ugID = govtDataConfig.ugID {
            governmentIDs.append(ugID)
        }
        
        if authStep.config?.ugTELCO == true, let ugTELCO = govtDataConfig.ugTelco {
            governmentIDs.append(ugTELCO)
        }
        
//        if authStep.config?.keDL == true, let keDL = govtDataConfig.keDL {
//            governmentIDs.append(keDL)
//        }
        
        if authStep.config?.keID == true, let keID = govtDataConfig.keID {
            governmentIDs.append(keID)
        }
        
        if authStep.config?.keKRA == true, let keKRA = govtDataConfig.keKRA {
            governmentIDs.append(keKRA)
        }
        
        if authStep.config?.saDL == true, let saDL = govtDataConfig.saDL {
            governmentIDs.append(saDL)
        }
        
        if authStep.config?.saID == true, let saID = govtDataConfig.saID {
            governmentIDs.append(saID)
        }
        
        if authStep.config?.cac == true, let cac = govtDataConfig.cac {
            governmentIDs.append(cac)
        }
        
        return governmentIDs
    }
    
    static func getVerificationMethods(for pageName: DJPageName, preference: PreferenceProtocol) -> [DJGovernmentID] {
        guard let govtDataConfig = preference.DJGovernmentIDConfig,
              let authStep = preference.DJSteps.first(where: { $0.name == pageName })
        else { return [] }
        
        var methods = [DJGovernmentID]()
        
        
        if authStep.config?.selfie == true, let selfieConfig = govtDataConfig.selfie, let selfieVideoConfig = govtDataConfig.selfieVideo {
            if authStep.config?.version == 3 {
                methods.append(selfieConfig)
            } else {
                methods.append(selfieVideoConfig)
            }
        }
        
        if authStep.config?.otp == true, let otpConfig = govtDataConfig.otp {
            methods.append(otpConfig)
        }
        
        if authStep.config?.whatsappOtp == true, let whatsappOtpConfig = govtDataConfig.whatsappOtp {
            methods.append(whatsappOtpConfig)
        }
        
        return methods
    }
    
    static func getBusinessDocumentTypes(preference: PreferenceProtocol) -> [DJGovernmentID] {
        guard let govtDataConfig = preference.DJGovernmentIDConfig,
              let authStep = preference.DJSteps.first(where: { $0.name == .businessData })
        else { return [] }
        
        var governmentIDs = [DJGovernmentID]()
        
        if authStep.config?.cac == true, let cacConfig = govtDataConfig.cac {
            governmentIDs.append(cacConfig)
        }
        
        if authStep.config?.tin == true, let tinConfig = govtDataConfig.tin {
            governmentIDs.append(tinConfig)
        }
        
        return governmentIDs
    }
    
}
