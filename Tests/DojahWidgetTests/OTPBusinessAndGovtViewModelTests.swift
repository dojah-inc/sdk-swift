import XCTest
@testable import DojahWidget

final class OTPBusinessAndGovtViewModelTests: XCTestCase {
    func testOTPVerificationInfoAndRequestChannel() {
        let preference = MockPreference()
        preference.DJOTPVerificationInfo = "08012345678"
        preference.DJAuthStep = TestFixtures.authStep(name: .phoneNumber)
        let otp = MockOTPRemoteDatasource()
        let view = MockOTPView()
        let sut = OTPVerificationViewModel(otpRemoteDatasource: otp, preference: preference)
        sut.viewProtocol = view
        XCTAssertTrue(sut.isPhoneNumberVerification)
        XCTAssertEqual(sut.verificationInfo, "XXXXXXX5678")

        preference.DJAuthStep = TestFixtures.authStep(name: .email)
        preference.DJOTPVerificationInfo = "user@example.com"
        XCTAssertEqual(sut.verificationInfo, "user@example.com")
    }

    func testRequestOTPSuccessAndFailure() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .phoneNumber)
        preference.DJOTPVerificationInfo = "08012345678"
        preference.DJVerificationMethod = "sms"
        let otp = MockOTPRemoteDatasource()
        let view = MockOTPView()
        let sut = OTPVerificationViewModel(otpRemoteDatasource: otp, preference: preference)
        sut.viewProtocol = view

        sut.requestOTP()
        waitForRunAfter(delay: 0.2)
        XCTAssertEqual(otp.requestParams?["destination"] as? String, "08012345678")
        XCTAssertEqual(otp.requestParams?["channel"] as? String, "sms")
        XCTAssertTrue(view.startTimerCalled)

        otp.requestResult = .success(EntityResponse(entity: []))
        sut.requestOTP()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.OTPCouldNotBeSent.uiMessage)

        otp.requestResult = .failure(.serverFailure)
        sut.requestOTP()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.OTPCouldNotBeSent.uiMessage)
    }

    func testRequestOTPUsesEmailParam() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .email)
        preference.DJOTPVerificationInfo = "a@b.com"
        let otp = MockOTPRemoteDatasource()
        let sut = OTPVerificationViewModel(otpRemoteDatasource: otp, preference: preference)
        sut.requestOTP()
        XCTAssertEqual(otp.requestParams?["email"] as? String, "a@b.com")
        XCTAssertEqual(otp.requestParams?["channel"] as? String, "email")
        XCTAssertNil(otp.requestParams?["destination"])
    }

    func testVerifyOTPValidInvalidAndNetworkError() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .userData, id: 1)
        preference.DJSteps = [
            TestFixtures.authStep(name: .userData, id: 1),
            TestFixtures.authStep(name: .email, id: 2)
        ]
        let otp = MockOTPRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let view = MockOTPView()
        let sut = OTPVerificationViewModel(
            otpRemoteDatasource: otp,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view
        sut.otp = "1234"
        otp.requestResult = .success(EntityResponse(entity: [
            OTPRequestResponse(referenceID: "ref-1", destination: nil, statusID: nil, status: nil)
        ]))
        sut.requestOTP()
        sut.verifyOTP()
        XCTAssertEqual(otp.validateParams?["code"] as? String, "1234")
        XCTAssertEqual(otp.validateParams?["reference_id"] as? String, "ref-1")
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted })
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .email)

        otp.validateResult = .success(EntityResponse(entity: OTPValidationResponse(valid: false)))
        sut.verifyOTP()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.invalidOTPEntered.uiMessage)
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepFailed && $0.value == "04" })

        otp.validateResult = .failure(.tryAgain)
        sut.verifyOTP()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.tryAgain.uiMessage)
    }

    func testBusinessDataDocumentSelectionAndValidation() {
        let preference = MockPreference()
        preference.DJSteps = [
            TestFixtures.authStep(name: .businessData, id: 1, config: DJPageConfig(cac: true, tin: true))
        ]
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            cac: TestFixtures.governmentID(name: "CAC", idEnum: "RC-NUMBER"),
            tin: TestFixtures.governmentID(name: "TIN", idEnum: "TIN")
        )
        let view = MockBusinessDataView()
        let remote = MockBusinessDataRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let sut = BusinessDataViewModel(
            remoteDatasource: remote,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view
        XCTAssertEqual(sut.documentTypes.count, 2)
        XCTAssertEqual(sut.companyTypes, CompanyType.allCases)

        sut.verifyBusiness(name: "Dojah", number: "123")
        waitForMainQueue()
        XCTAssertEqual(view.shownError, "Choose a document type")

        sut.didChooseDocumentType(at: 0)
        XCTAssertEqual(sut.selectedDocument?.idEnum, "RC-NUMBER")
        XCTAssertEqual(view.companyTypeHidden, false)
        XCTAssertEqual(view.businessNameHidden, true)
        sut.didChooseCompanyType(at: 0)
        XCTAssertEqual(sut.selectedCompanyType, .businessName)

        sut.didChooseDocumentType(at: 1)
        XCTAssertEqual(view.companyTypeHidden, true)
        XCTAssertEqual(view.businessNameHidden, false)
    }

    func testBusinessDataVerifySuccessFailureAndUnknownType() {
        let preference = MockPreference()
        preference.DJCountryCode = "NG"
        preference.DJAuthStep = TestFixtures.authStep(name: .businessData, id: 1)
        preference.DJSteps = [
            TestFixtures.authStep(name: .businessData, id: 1, config: DJPageConfig(cac: true)),
            TestFixtures.authStep(name: .email, id: 2)
        ]
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            cac: TestFixtures.governmentID(name: "CAC", idEnum: "RC-NUMBER")
        )
        let remote = MockBusinessDataRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let view = MockBusinessDataView()
        let sut = BusinessDataViewModel(
            remoteDatasource: remote,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view
        sut.didChooseDocumentType(at: 0)
        sut.didChooseCompanyType(at: 0)
        sut.verifyBusiness(name: "Dojah", number: "123456")

        XCTAssertEqual(remote.lastType, .cac)
        XCTAssertEqual(remote.lastParams?["rc_number"] as? String, "123456")
        XCTAssertEqual(remote.lastParams?["company_type"] as? String, "BUSINESS_NAME")
        XCTAssertTrue(events.postedEvents.contains { $0.name == .verificationTypeSelected })
        XCTAssertTrue(events.postedEvents.contains { $0.name == .customerBusinessDataCollected })
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .email)

        remote.result = .success(EntityResponse(entity: nil))
        sut.verifyBusiness(name: "Dojah", number: "123456")
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.invalidIDNotFoundBusinessData(.cac).uiMessage)

        remote.result = .failure(.serverFailure)
        sut.verifyBusiness(name: "Dojah", number: "123456")
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.serverFailure.uiMessage)
    }

    func testGovtIDOptionsSelectionAndContinue() {
        let preference = MockPreference()
        preference.DJCurrentPageID = 0
        preference.DJAuthStep = TestFixtures.authStep(name: .id, id: 1)
        preference.DJSteps = [
            TestFixtures.authStep(name: .id, id: 1, config: DJPageConfig(nin: true)),
            TestFixtures.authStep(name: .selfie, id: 2)
        ]
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            nin: TestFixtures.governmentID(name: "NIN", value: "NIN")
        )
        let events = MockEventsRemoteDatasource()
        var shownID: DJGovernmentID?
        let sut = GovtIDOptionsViewModel(eventsRemoteDatasource: events, preference: preference)
        sut.showGovtIDPage = { shownID = $0 }

        sut.didTapContinue()
        XCTAssertNil(shownID)

        sut.didChooseIdentificationType(at: 0)
        sut.didTapContinue()
        XCTAssertEqual(events.postedEvents.map(\.name), [
            .verificationTypeSelected, .verificationModeSelected, .stepCompleted
        ])
        XCTAssertEqual(shownID?.value, "NIN")
        XCTAssertEqual(preference.DJAuthStep.name, .selfie)
    }

    func testGovernmentDataSelectionFiltersDLToSelfie() {
        let preference = MockPreference()
        preference.DJCurrentPageID = 0
        preference.DJSteps = [
            TestFixtures.authStep(
                name: .governmentData,
                id: 1,
                config: DJPageConfig(bvn: true, dl: true, otp: true, selfie: true, version: 3)
            )
        ]
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            bvn: TestFixtures.governmentID(name: "BVN", idEnum: "BVN", value: "BVN"),
            dl: TestFixtures.governmentID(name: "DL", idEnum: "DL", value: "DL"),
            selfie: TestFixtures.governmentID(name: "selfie"),
            selfieVideo: TestFixtures.governmentID(name: "selfie-video"),
            otp: TestFixtures.governmentID(name: "SMS OTP")
        )
        let view = MockGovernmentDataView()
        let remote = MockGovernmentDataRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let sut = DJGovernmentDataViewModel(
            remoteDatasource: remote,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view

        XCTAssertEqual(sut.governmentIDs.names.sorted(), ["BVN", "DL"])
        XCTAssertEqual(sut.governmentIDVerificationMethods.names, ["selfie", "SMS OTP"])

        sut.didChooseGovernmentData(at: 1, type: .id)
        XCTAssertEqual(sut.selectedGovernmentID?.idType, .dl)
        XCTAssertTrue(view.showNumberFieldCalled)
        XCTAssertEqual(sut.governmentIDVerificationMethods.names, ["selfie"])
        XCTAssertTrue(view.updateMethodsCalled)

        sut.didChooseGovernmentData(at: 0, type: .id)
        XCTAssertEqual(sut.governmentIDVerificationMethods.names, ["selfie", "SMS OTP"])

        sut.didChooseGovernmentData(at: 1, type: .verificationMethod)
        XCTAssertEqual(preference.DJSelectedGovernmentIDVerificationMethod?.name, "SMS OTP")
        XCTAssertTrue(events.postedEvents.contains { $0.name == .verificationModeSelected && $0.value == "OTP" })
    }

    func testGovernmentDataContinueLookupSuccessAndErrors() {
        let preference = MockPreference()
        preference.DJCountryCode = "NG"
        preference.DJCurrentPageID = 0
        preference.DJAuthStep = TestFixtures.authStep(name: .governmentData, id: 1, config: DJPageConfig(bvn: true, otp: true, selfie: true, version: 3))
        preference.DJSteps = [
            TestFixtures.authStep(name: .governmentData, id: 1, config: DJPageConfig(bvn: true, otp: true, selfie: true, version: 3)),
            TestFixtures.authStep(name: .governmentDataVerification, id: 2)
        ]
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            bvn: TestFixtures.governmentID(name: "BVN", idEnum: "BVN", value: "BVN"),
            selfie: TestFixtures.governmentID(name: "selfie"),
            selfieVideo: TestFixtures.governmentID(name: "selfie-video"),
            otp: TestFixtures.governmentID(name: "SMS OTP")
        )
        let remote = MockGovernmentDataRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let view = MockGovernmentDataView()
        let sut = DJGovernmentDataViewModel(
            remoteDatasource: remote,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view
        sut.idNumber = "22222222222"
        sut.didTapContinue()
        XCTAssertNil(remote.lastNumber)

        sut.didChooseGovernmentData(at: 0, type: .id)
        sut.didChooseGovernmentData(at: 1, type: .verificationMethod)
        sut.didTapContinue()
        XCTAssertEqual(remote.lastIDType, .bvn)
        XCTAssertEqual(remote.lastNumber, "22222222222")
        XCTAssertTrue(events.postedEvents.contains { $0.name == .verificationTypeSelected })
        XCTAssertTrue(events.postedEvents.contains { $0.name == .customerGovernmentDataCollected })
        XCTAssertTrue(events.postedEvents.contains { $0.name == .governmentImageCollected })
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted })
        XCTAssertEqual(preference.DJOTPVerificationInfo, "08012345678")
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .governmentDataVerification)

        remote.result = .success(EntityResponse(entity: nil))
        sut.didTapContinue()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.invalidIDNotFoundGovernmentData(.bvn).uiMessage)

        remote.result = .failure(.invalidIDThirdPartyFailure)
        sut.didTapContinue()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.invalidIDNotFoundThirdPartyMessage(.bvn).uiMessage)

        remote.result = .failure(.invalidIDNotFoundThirdParty)
        sut.didTapContinue()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.invalidIDNotFoundGovernmentData(.bvn).uiMessage)

        remote.result = .failure(.serverFailure)
        sut.didTapContinue()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.serverFailure.uiMessage)
    }

    func testGovernmentDataUsesBvnAdvanceWhenConfigured() {
        let preference = MockPreference()
        preference.DJCurrentPageID = 0
        preference.DJAuthStep = TestFixtures.authStep(name: .governmentData, id: 1, config: DJPageConfig(bvn: true, bvnAdvance: true))
        preference.DJSteps = [preference.DJAuthStep]
        preference.DJGovernmentIDConfig = TestFixtures.governmentIDConfig(
            bvn: TestFixtures.governmentID(name: "BVN", idEnum: "BVN", value: "BVN")
        )
        let remote = MockGovernmentDataRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let sut = DJGovernmentDataViewModel(
            remoteDatasource: remote,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.idNumber = "222"
        sut.didChooseGovernmentData(at: 0, type: .id)
        sut.didTapContinue()
        XCTAssertEqual(remote.lastIDType, .bvnAdvance)
        XCTAssertEqual(sut.selectedGovernmentID?.value, "bvnAdvance")
    }
}
