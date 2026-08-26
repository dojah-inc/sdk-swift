import XCTest
@testable import DojahWidget

final class UserDefaultWrapperTests: XCTestCase {
    private let defaults = UserDefaults.standard

    override func tearDown() {
        PreferenceKey.allCasesForTests.forEach { defaults.removeObject(forKey: $0.rawValue) }
        super.tearDown()
    }

    func testPrimitiveDefaultAndRoundTrip() {
        var wrapper = UserDefaultPrimitive<String>(key: .DJWidgetID, default: "unset")
        XCTAssertEqual(wrapper.wrappedValue, "unset")
        wrapper.wrappedValue = "wid-1"
        XCTAssertEqual(wrapper.wrappedValue, "wid-1")
        XCTAssertEqual(defaults.string(forKey: PreferenceKey.DJWidgetID.rawValue), "wid-1")
    }

    func testCodableDefaultNilAndRoundTrip() {
        var wrapper = UserDefaultCodable<DJAppConfig?>(key: .DJAppConfig, default: nil)
        XCTAssertNil(wrapper.wrappedValue)
        wrapper.wrappedValue = DJAppConfig(name: "App", logo: nil, colorCode: "#fff", id: "1")
        XCTAssertEqual(wrapper.wrappedValue?.name, "App")
        XCTAssertEqual(wrapper.wrappedValue?.id, "1")
    }

    func testPreferenceImplReadsAndWritesIsolatedKeys() {
        var preference = PreferenceImpl()
        preference.DJWidgetID = "wid-test"
        preference.DJCanSeeCountryPage = true
        preference.DJVerificationID = 42
        preference.DJCountryCode = "KE"
        XCTAssertEqual(preference.DJWidgetID, "wid-test")
        XCTAssertTrue(preference.DJCanSeeCountryPage)
        XCTAssertEqual(preference.DJVerificationID, 42)
        XCTAssertEqual(preference.DJCountryCode, "KE")
    }
}

private extension PreferenceKey {
    static var allCasesForTests: [PreferenceKey] {
        [
            .DJWidgetID, .DJVerificationMethod, .DJConfigurationInitialized, .DJAppConfig,
            .DJRequestHeaders, .DJUserAgent, .DJIPCountry, .DJCanSeeCountryPage, .DJVerificationID,
            .DJSteps, .DJAuthStep, .DJGovernmentIDConfig, .DJCountryCode,
            .DJSelectedGovernmentIDVerificationMethod, .DJOTPVerificationInfo, .DJPreAuthEmailAddress,
            .PlatformSource, .WidgetIDCache, .DJPreAuthResponse, .DJPricingServicesConfig,
            .VerificationResultStatus, .ExtraUserData, .DJCountryStates, .DJCurrentPageID
        ]
    }
}
