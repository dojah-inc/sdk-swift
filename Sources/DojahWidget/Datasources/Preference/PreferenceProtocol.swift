//
//  PreferenceProtocol.swift
//
//
//  Created by Isaac Iniongun on 01/12/2023.
//

import Foundation

protocol PreferenceProtocol {
    var DJWidgetID: String { get set }
    var DJConfigurationInitialized: Bool { get set }
    var DJAppConfig: DJAppConfig? { get set }
    var DJRequestHeaders: DJHeaderParameters { get set }
    var DJUserAgent: String { get set }
    var DJIPCountry: String { get set }
    var DJCanSeeCountryPage: Bool { get set }
    var DJVerificationID: Int { get set }
    var DJSteps: [DJAuthStep] { get set }
    var DJAuthStep: DJAuthStep { get set }
    var DJGovernmentIDConfig: DJGovernmentIDConfig? { get set }
    var DJCountryCode: String { get set }
}
