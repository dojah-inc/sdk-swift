import XCTest
@testable import DojahWidget

final class FactoryTests: XCTestCase {
    private var preference: MockPreference!

    override func setUp() {
        super.setUp()
        preference = MockPreference()
    }

    func testGetGovernmentIDs_returnsEmptyWhenConfigMissingOrPageMismatch() {
        preference.DJGovernmentIDConfig = nil
        XCTAssertTrue(GovernmentIDFactory.getGovernmentIDs(for: .governmentData, preference: preference).isEmpty)

        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(bvn: TestFixtures.governmentID())
        preference.DJCurrentPageID = 0
        preference.DJSteps = [TestFixtures.authStep(name: .index, id: 0, config: DJPageConfig(bvn: true))]
        XCTAssertTrue(GovernmentIDFactory.getGovernmentIDs(for: .governmentData, preference: preference).isEmpty)
    }

    func testGetGovernmentIDs_includesEnabledConfiguredTypes() {
        preference.DJCurrentPageID = 0
        preference.DJSteps = [
            TestFixtures.authStep(
                name: .governmentData,
                id: 1,
                config: DJPageConfig(
                    bvn: true,
                    dl: true,
                    vnin: true,
                    nin: true,
                    cac: true,
                    passport: true,
                    voter: true,
                    national: true,
                    ghVoter: true,
                    keID: true,
                    keKRA: true,
                    tzNIN: true,
                    ugID: true,
                    ugTELCO: true,
                    saID: true,
                    saDL: true
                )
            )
        ]
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            bvn: TestFixtures.governmentID(name: "BVN", idEnum: "BVN"),
            nin: TestFixtures.governmentID(name: "NIN", idEnum: "NIN"),
            vnin: TestFixtures.governmentID(name: "VNIN", idEnum: "VNIN"),
            dl: TestFixtures.governmentID(name: "DL", idEnum: "DL"),
            passport: TestFixtures.governmentID(name: "PASS", idEnum: "PASSPORT"),
            national: TestFixtures.governmentID(name: "NAT", idEnum: "NAT"),
            voter: TestFixtures.governmentID(name: "VOTER", idEnum: "VOTER"),
            selfie: TestFixtures.governmentID(name: "selfie"),
            otp: TestFixtures.governmentID(name: "otp"),
            ghVoter: TestFixtures.governmentID(name: "GH-VOTER"),
            tzNIN: TestFixtures.governmentID(name: "TZ-NIN"),
            ugID: TestFixtures.governmentID(name: "UG-ID"),
            ugTelco: TestFixtures.governmentID(name: "UG-TELCO"),
            keID: TestFixtures.governmentID(name: "KE-ID"),
            keKRA: TestFixtures.governmentID(name: "KE-KRA"),
            saDL: TestFixtures.governmentID(name: "SA-DL"),
            saID: TestFixtures.governmentID(name: "SA-ID"),
            cac: TestFixtures.governmentID(name: "CAC", idEnum: "RC-NUMBER")
        )

        let ids = GovernmentIDFactory.getGovernmentIDs(for: .governmentData, preference: preference)
        XCTAssertEqual(ids.names.sorted(), [
            "BVN", "CAC", "DL", "GH-VOTER", "KE-ID", "KE-KRA", "NAT", "NIN",
            "PASS", "SA-DL", "SA-ID", "TZ-NIN", "UG-ID", "UG-TELCO", "VNIN", "VOTER"
        ].sorted())
    }

    func testGetGovernmentIDs_skipsEnabledTypesWithoutConfig() {
        preference.DJCurrentPageID = 0
        preference.DJSteps = [
            TestFixtures.authStep(name: .governmentData, id: 1, config: DJPageConfig(bvn: true, nin: true))
        ]
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            bvn: TestFixtures.governmentID(name: "BVN")
        )
        XCTAssertEqual(GovernmentIDFactory.getGovernmentIDs(for: .governmentData, preference: preference).names, ["BVN"])
    }

    func testGetVerificationMethods_version3UsesSelfieElseVideo() {
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            selfie: TestFixtures.governmentID(name: "selfie"),
            selfieVideo: TestFixtures.governmentID(name: "selfie-video"),
            otp: TestFixtures.governmentID(name: "otp"),
            whatsappOtp: TestFixtures.governmentID(name: "whatsappotp")
        )
        preference.DJSteps = [
            TestFixtures.authStep(
                name: .governmentData,
                id: 1,
                config: DJPageConfig(otp: true, selfie: true, whatsappOtp: true, version: 3)
            )
        ]
        XCTAssertEqual(
            GovernmentIDFactory.getVerificationMethods(for: .governmentData, preference: preference).names,
            ["selfie", "otp", "whatsappotp"]
        )

        preference.DJSteps = [
            TestFixtures.authStep(
                name: .governmentData,
                id: 1,
                config: DJPageConfig(otp: true, selfie: true, version: 2)
            )
        ]
        XCTAssertEqual(
            GovernmentIDFactory.getVerificationMethods(for: .governmentData, preference: preference).names,
            ["selfie-video", "otp"]
        )
    }

    func testGetVerificationMethods_returnsEmptyWithoutMatchingStep() {
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig()
        preference.DJSteps = [TestFixtures.authStep(name: .email)]
        XCTAssertTrue(GovernmentIDFactory.getVerificationMethods(for: .governmentData, preference: preference).isEmpty)
    }

    func testGetBusinessDocumentTypes() {
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            cac: TestFixtures.governmentID(name: "CAC", idEnum: "RC-NUMBER"),
            tin: TestFixtures.governmentID(name: "TIN", idEnum: "TIN")
        )
        preference.DJSteps = [
            TestFixtures.authStep(name: .businessData, id: 2, config: DJPageConfig(cac: true, tin: true))
        ]
        XCTAssertEqual(
            GovernmentIDFactory.getBusinessDocumentTypes(preference: preference).names,
            ["CAC", "TIN"]
        )

        preference.DJSteps = [TestFixtures.authStep(name: .email)]
        XCTAssertTrue(GovernmentIDFactory.getBusinessDocumentTypes(preference: preference).isEmpty)
    }

    func testPricingServicesFactory_returnsEmptyWithoutConfigOrForStaticPages() {
        let factory = PricingServicesFactory(preference: preference)
        XCTAssertTrue(factory.services().isEmpty)

        preference.DJPricingServicesConfig = TestFixtures.pricingServicesConfig()
        preference.DJAuthStep = TestFixtures.authStep(name: .index)
        XCTAssertTrue(factory.services().isEmpty)
        preference.DJAuthStep = TestFixtures.authStep(name: .countries)
        XCTAssertTrue(factory.services().isEmpty)
        preference.DJAuthStep = TestFixtures.authStep(name: .customQuestions)
        XCTAssertTrue(factory.services().isEmpty)
    }

    func testPricingServicesFactory_verificationPagesNeedVerificationFlag() {
        preference.DJPricingServicesConfig = TestFixtures.pricingServicesConfig()
        let factory = PricingServicesFactory(preference: preference)

        preference.DJAuthStep = TestFixtures.authStep(name: .phoneNumber, config: DJPageConfig(verification: false))
        XCTAssertTrue(factory.services().isEmpty)
        preference.DJAuthStep = TestFixtures.authStep(name: .phoneNumber, config: DJPageConfig(verification: true))
        XCTAssertEqual(factory.services(), ["verification-svc"])

        preference.DJAuthStep = TestFixtures.authStep(name: .email, config: DJPageConfig(verification: true))
        XCTAssertEqual(factory.services(), ["verification-svc"])
        preference.DJAuthStep = TestFixtures.authStep(name: .address, config: DJPageConfig(verification: true))
        XCTAssertEqual(factory.services(), ["verification-svc"])
    }

    func testPricingServicesFactory_pageSpecificServices() {
        preference.DJPricingServicesConfig = TestFixtures.pricingServicesConfig()
        let factory = PricingServicesFactory(preference: preference)

        preference.DJAuthStep = TestFixtures.authStep(name: .businessData)
        XCTAssertEqual(factory.services(), ["cac-svc"])
        preference.DJAuthStep = TestFixtures.authStep(name: .id)
        XCTAssertEqual(factory.services(), ["id-default-svc"])
        preference.DJAuthStep = TestFixtures.authStep(name: .businessID)
        XCTAssertEqual(factory.services(), ["id-default-svc"])
    }

    func testPricingServicesFactory_governmentDataByIDType() {
        preference.DJPricingServicesConfig = TestFixtures.pricingServicesConfig()
        preference.DJAuthStep = TestFixtures.authStep(name: .governmentData)
        let factory = PricingServicesFactory(preference: preference)

        XCTAssertTrue(factory.services().isEmpty)
        XCTAssertEqual(factory.services(governmentIDType: .bvn), ["bvn-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .bvnAdvance), ["bvn-adv-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .nin), ["nin-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .vnin), ["vnin-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .dl), ["dl-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .mobile), ["mobile-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .ghDL), ["gh-dl-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .ghVotersCard), ["gh-voter-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .keDL), ["ke-dl-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .keID), ["ke-id-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .keKRA), ["ke-kra-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .aoNin), ["ao-nin-svc"])
        XCTAssertEqual(factory.services(governmentIDType: .zaId), ["za-id-svc"])
        XCTAssertTrue(factory.services(governmentIDType: .passportID).isEmpty)
    }

    func testPricingServicesFactory_governmentDataVerificationByMethod() {
        preference.DJPricingServicesConfig = TestFixtures.pricingServicesConfig()
        preference.DJAuthStep = TestFixtures.authStep(name: .governmentDataVerification)
        let factory = PricingServicesFactory(preference: preference)

        XCTAssertTrue(factory.services().isEmpty)
        XCTAssertTrue(factory.services(verificationMethod: .govtID).isEmpty)
        XCTAssertEqual(factory.services(verificationMethod: .selfie), ["selfie-svc"])
        XCTAssertEqual(factory.services(verificationMethod: .phoneNumberOTP), ["otp-svc"])
        XCTAssertEqual(factory.services(verificationMethod: .emailOTP), ["email-otp-svc"])
        XCTAssertEqual(factory.services(verificationMethod: .selfieVideo), ["video-svc"])
        XCTAssertEqual(factory.services(verificationMethod: .whatsappOtp), ["whatsapp-svc"])

        preference.DJAuthStep = TestFixtures.authStep(name: .selfie)
        XCTAssertEqual(factory.services(verificationMethod: .selfie), ["selfie-svc"])
    }
}
