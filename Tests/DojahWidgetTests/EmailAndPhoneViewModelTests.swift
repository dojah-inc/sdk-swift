import XCTest
@testable import DojahWidget

final class EmailAndPhoneViewModelTests: XCTestCase {
    func testEmailDidTapContinue_invalidEmailShowsError() {
        let validator = MockInputValidator()
        validator.genericResult = ValidationMessage(isValid: false, message: "Invalid email address", validationType: .email)
        let view = MockEmailView()
        let sut = EmailViewModel(
            validator: validator,
            eventsRemoteDatasource: MockEventsRemoteDatasource(),
            preference: MockPreference()
        )
        sut.viewProtocol = view

        sut.didTapContinue(email: "bad")
        XCTAssertEqual(view.shownEmailError, "Invalid email address")
        XCTAssertFalse(view.hideEmailErrorCalled)
        XCTAssertFalse(view.showVerifyCalled)
    }

    func testEmailDidTapContinue_verificationEnabledShowsOTP() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .email, config: DJPageConfig(verification: true))
        let view = MockEmailView()
        let sut = EmailViewModel(
            validator: MockInputValidator(),
            eventsRemoteDatasource: MockEventsRemoteDatasource(),
            preference: preference
        )
        sut.viewProtocol = view

        sut.didTapContinue(email: "user@example.com")
        XCTAssertTrue(view.hideEmailErrorCalled)
        XCTAssertTrue(view.showVerifyCalled)
        XCTAssertEqual(preference.DJOTPVerificationInfo, "user@example.com")
    }

    func testEmailDidTapContinue_postsCollectedEventAndAdvances() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .email, id: 1, config: DJPageConfig(verification: false))
        preference.DJSteps = [
            TestFixtures.authStep(name: .email, id: 1),
            TestFixtures.authStep(name: .userData, id: 2)
        ]
        let events = MockEventsRemoteDatasource()
        let view = MockEmailView()
        let sut = EmailViewModel(validator: MockInputValidator(), eventsRemoteDatasource: events, preference: preference)
        sut.viewProtocol = view

        sut.didTapContinue(email: "user@example.com")
        XCTAssertEqual(events.postedEmailEvents.first?.name, .emailCollected)
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted && $0.value == "email" })
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .userData)
    }

    func testEmailCollectedDuplicateReferenceShowsSuccess() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .email, config: DJPageConfig(verification: false))
        let events = MockEventsRemoteDatasource()
        events.postEmailResult = .success(EntityResponse(entity: EmailCollectedEventResponse(
            success: true, continueVerification: false, duplicateReference: true, data: nil, msg: nil, message: nil
        )))
        var message: FeedbackConfig?
        let sut = EmailViewModel(validator: MockInputValidator(), eventsRemoteDatasource: events, preference: preference)
        sut.showMessage = { message = $0 }

        sut.didTapContinue(email: "user@example.com")
        XCTAssertEqual(message?.titleText, "Verification successful")
        XCTAssertEqual(message?.feedbackType, .success)
    }

    func testEmailCollectedFailureAndNilEntity() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .email, config: DJPageConfig(verification: false))
        let events = MockEventsRemoteDatasource()
        let view = MockEmailView()
        let sut = EmailViewModel(validator: MockInputValidator(), eventsRemoteDatasource: events, preference: preference)
        sut.viewProtocol = view

        events.postEmailResult = .success(EntityResponse(entity: nil))
        sut.didTapContinue(email: "user@example.com")
        XCTAssertEqual(view.shownError, DJSDKError.tryAgain.uiMessage)

        events.postEmailResult = .success(EntityResponse(entity: EmailCollectedEventResponse(
            success: false, continueVerification: false, duplicateReference: false, data: nil, msg: nil, message: "bad email"
        )))
        sut.didTapContinue(email: "user@example.com")
        XCTAssertEqual(view.shownError, "bad email")

        events.postEmailResult = .failure(.serverFailure)
        sut.didTapContinue(email: "user@example.com")
        XCTAssertEqual(view.shownError, DJSDKError.serverFailure.uiMessage)
    }

    func testEmailContinueVerificationUpdatesPreference() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .email, id: 1, config: DJPageConfig(verification: false))
        preference.DJRequestHeaders = [:]
        let config = DJInitDataConfig(
            verificationID: 99,
            steps: [
                TestFixtures.authStep(name: .userData, id: 2, status: .notdone),
                TestFixtures.authStep(name: .selfie, id: 3, status: .done)
            ],
            stepNumber: 1,
            referenceID: "ref-1",
            sessionID: "sess-1",
            verificationTypeSelected: nil
        )
        let events = MockEventsRemoteDatasource()
        events.postEmailResult = .success(EntityResponse(entity: EmailCollectedEventResponse(
            success: true, continueVerification: true, duplicateReference: false, data: config, msg: nil, message: nil
        )))
        let sut = EmailViewModel(validator: MockInputValidator(), eventsRemoteDatasource: events, preference: preference)

        sut.didTapContinue(email: "user@example.com")
        XCTAssertEqual(preference.DJVerificationID, 99)
        XCTAssertEqual(preference.DJRequestHeaders["session"], "sess-1")
        XCTAssertEqual(preference.DJRequestHeaders["reference"], "ref-1")
        XCTAssertEqual(preference.DJSteps.map(\.name), [.userData])
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .userData)
    }

    func testSetupPreAuthEmailAddressPrefillsWhenPresent() {
        let preference = MockPreference()
        preference.preAuthEmailAddress = "saved@example.com"
        preference.DJAuthStep = TestFixtures.authStep(name: .email, config: DJPageConfig(verification: true))
        let view = MockEmailView()
        let sut = EmailViewModel(validator: MockInputValidator(), preference: preference)
        sut.viewProtocol = view

        sut.setupPreAuthEmailAddress()
        XCTAssertEqual(view.prefilledEmail, "saved@example.com")
        XCTAssertTrue(view.showVerifyCalled)
    }

    func testSetupPreAuthEmailAddressIgnoresEmpty() {
        let preference = MockPreference()
        preference.preAuthEmailAddress = ""
        let view = MockEmailView()
        let sut = EmailViewModel(validator: MockInputValidator(), preference: preference)
        sut.viewProtocol = view
        sut.setupPreAuthEmailAddress()
        XCTAssertNil(view.prefilledEmail)
    }

    func testPhoneNumberVerificationMethods() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .phoneNumber, config: DJPageConfig(otp: true, verification: false))
        let sut = PhoneNumberViewModel(
            countriesLocalDatasource: MockCountriesLocalDatasource(),
            preference: preference
        )
        XCTAssertTrue(sut.verificationMethods.isEmpty)

        preference.DJAuthStep = TestFixtures.authStep(
            name: .phoneNumber,
            config: DJPageConfig(otp: true, verification: true, whatsappVerification: true)
        )
        XCTAssertEqual(sut.verificationMethods, ["SMS", "WhatsApp"])
    }

    func testPhoneNumberCountrySelectionAndContinueButton() {
        let countries = [
            TestFixtures.country(iso2: "GH", countryName: "Ghana", phoneCode: "233"),
            TestFixtures.country(iso2: "NG", countryName: "Nigeria", phoneCode: "234")
        ]
        let view = MockPhoneNumberView()
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(
            name: .phoneNumber,
            config: DJPageConfig(otp: true, verification: true)
        )
        let sut = PhoneNumberViewModel(
            countriesLocalDatasource: MockCountriesLocalDatasource(countries: countries),
            preference: preference
        )
        sut.viewProtocol = view
        XCTAssertEqual(sut.countries.map(\.phoneCode), ["233", "234"])

        sut.didChooseCountry(index: -1)
        sut.didChooseCountry(index: 99)
        XCTAssertNil(view.lastPhoneCode)

        sut.didChooseCountry(index: 0)
        XCTAssertEqual(view.lastPhoneCode, "233")

        sut.numberDidChange("")
        XCTAssertEqual(view.continueEnabled, false)
        sut.didChooseVerificationMethod(index: 0)
        XCTAssertEqual(view.continueEnabled, false)
        sut.numberDidChange("0803")
        XCTAssertEqual(view.continueEnabled, true)
    }

    func testPhoneNumberDidTapContinue_withVerificationShowsOTP() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(
            name: .phoneNumber,
            config: DJPageConfig(otp: true, verification: true)
        )
        let view = MockPhoneNumberView()
        let sut = PhoneNumberViewModel(
            countriesLocalDatasource: MockCountriesLocalDatasource(),
            preference: preference
        )
        sut.viewProtocol = view
        sut.didChooseVerificationMethod(index: 0)
        sut.numberDidChange("08012345678")
        sut.didTapContinue()
        XCTAssertEqual(preference.DJOTPVerificationInfo, "08012345678")
        XCTAssertEqual(preference.DJVerificationMethod, "sms")
        XCTAssertTrue(view.showVerifyCalled)
    }

    func testPhoneNumberDidTapContinue_withoutVerificationPostsEvents() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .phoneNumber, id: 1, config: DJPageConfig(verification: false))
        preference.DJSteps = [
            TestFixtures.authStep(name: .phoneNumber, id: 1),
            TestFixtures.authStep(name: .email, id: 2)
        ]
        let events = MockEventsRemoteDatasource()
        let sut = PhoneNumberViewModel(
            countriesLocalDatasource: MockCountriesLocalDatasource(),
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.numberDidChange("0803")
        sut.didTapContinue()
        XCTAssertTrue(events.postedEvents.contains { $0.name == .phoneNumberValidation })
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted })
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .email)
    }
}
