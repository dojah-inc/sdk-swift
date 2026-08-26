import Foundation
@testable import DojahWidget

final class MockPreference: PreferenceProtocol {
    var DJWidgetID: String = ""
    var DJCurrentPageID: Int = 0
    var preAuthEmailAddress: String = ""
    var DJConfigurationInitialized: Bool = false
    var DJAppConfig: DJAppConfig?
    var preAuthResponse: DJPreAuthResponse?
    var DJRequestHeaders: DJHeaderParameters = [:]
    var DJUserAgent: String = ""
    var DJIPCountry: String = "NG"
    var DJCanSeeCountryPage: Bool = false
    var DJVerificationID: Int = 0
    var DJSteps: [DJAuthStep] = [TestFixtures.authStep()]
    var DJAuthStep: DJAuthStep = TestFixtures.authStep()
    var DJGovernmentIDConfig: DJGovernmentIDConfig?
    var DJCountryCode: String = "NG"
    var DJSelectedGovernmentIDVerificationMethod: DJGovernmentID?
    var DJOTPVerificationInfo: String = ""
    var DJVerificationMethod: String = ""
    var WidgetIDCache: [WidgetIDCache] = []
    var DJPricingServicesConfig: PricingServicesConfig?
    var VerificationResultStatus: String = ""
    var DJExtraUserData: ExtraUserData?
    var DJCountryStates: [HomeCountry]?
    var platformSource: String? = "ios_native"
}
