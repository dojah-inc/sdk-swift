import XCTest
@testable import DojahWidget

final class FeatureViewModelTests: XCTestCase {
    func testCountryPickerFilterAndUnsupportedCountry() {
        let nigeria = TestFixtures.country(iso2: "NG")
        let kenya = TestFixtures.country(iso2: "KE", countryName: "Kenya", iso3: "KEN", phoneCode: "254")
        let preference = MockPreference()
        preference.preAuthResponse = DJPreAuthResponse(
            widget: DJWidget(
                published: true,
                reviewProcess: nil,
                pages: [TestFixtures.page(name: .governmentData, config: DJPageConfig(bvn: true, keID: true))],
                countries: ["NG"],
                env: nil,
                company: nil,
                duplicateCheck: nil,
                directFeedback: nil,
                rules: nil
            ),
            publicKey: "pk",
            appConfig: nil
        )
        let events = MockEventsRemoteDatasource()
        let view = MockCountryPickerView()
        let sut = CountryPickerViewModel(
            countriesLocalDatasource: MockCountriesLocalDatasource(countries: [nigeria, kenya]),
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view
        XCTAssertEqual(preference.DJCountryCode, "NG")

        sut.filterCountries("ke")
        XCTAssertEqual(sut.countries.map(\.iso2), ["KE"])
        XCTAssertTrue(view.refreshCalled)
        sut.filterCountries("")
        XCTAssertEqual(sut.countries.count, 2)

        sut.didChooseCountry(kenya)
        XCTAssertEqual(preference.DJCountryCode, "KE")
        XCTAssertEqual(view.continueEnabled, false)
        XCTAssertEqual(view.shownError, DJSDKError.countryNotSupported.uiMessage)
        XCTAssertEqual(events.postedEvents.first?.name, .countrySelected)

        sut.checkSupportedCountry(using: "NG")
        XCTAssertEqual(view.continueEnabled, true)
        XCTAssertTrue(view.hideMessageCalled)
    }

    func testCountryPickerDidTapContinueWithoutSelectionPostsNigeria() {
        let preference = MockPreference()
        preference.preAuthResponse = DJPreAuthResponse(
            widget: DJWidget(
                published: true, reviewProcess: nil, pages: nil, countries: ["NG"],
                env: nil, company: nil, duplicateCheck: nil, directFeedback: nil, rules: nil
            ),
            publicKey: nil,
            appConfig: nil
        )
        preference.DJAuthStep = TestFixtures.authStep(name: .countries, id: 1)
        preference.DJSteps = [
            TestFixtures.authStep(name: .countries, id: 1),
            TestFixtures.authStep(name: .userData, id: 2)
        ]
        let events = MockEventsRemoteDatasource()
        let sut = CountryPickerViewModel(
            countriesLocalDatasource: MockCountriesLocalDatasource(),
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.didTapContinue()
        XCTAssertTrue(events.postedEvents.contains { $0.name == .countrySelected && $0.value == "Nigeria" })
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted })
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .userData)
    }

    func testDisclaimerSupportedAndUnsupportedCountry() {
        let preference = MockPreference()
        preference.DJIPCountry = "NG"
        preference.DJCanSeeCountryPage = true
        preference.preAuthResponse = DJPreAuthResponse(
            widget: DJWidget(
                published: true, reviewProcess: nil, pages: nil, countries: ["NG"],
                env: nil, company: nil, duplicateCheck: nil, directFeedback: nil, rules: nil
            ),
            publicKey: nil, appConfig: nil
        )
        let view = MockDisclaimerView()
        let events = MockEventsRemoteDatasource()
        let sut = DJDisclaimerViewModel(eventsRemoteDatasource: events, preference: preference)
        sut.viewProtocol = view
        XCTAssertTrue(sut.canSeeCountryPage)
        sut.checkSupportedCountry()
        XCTAssertNil(view.shownError)

        preference.preAuthResponse = DJPreAuthResponse(
            widget: DJWidget(
                published: true, reviewProcess: nil, pages: nil, countries: ["KE"],
                env: nil, company: nil, duplicateCheck: nil, directFeedback: nil, rules: nil
            ),
            publicKey: nil, appConfig: nil
        )
        sut.checkSupportedCountry()
        XCTAssertEqual(view.continueEnabled, false)
        XCTAssertEqual(view.shownError, DJSDKError.countryNotSupported.uiMessage)

        preference.DJAuthStep = TestFixtures.authStep(name: .index, id: 0)
        preference.DJSteps = [
            TestFixtures.authStep(name: .index, id: 0),
            TestFixtures.authStep(name: .email, id: 1)
        ]
        sut.postStepCompletedEvent()
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .email)
    }

    func testSignatureConfirmPostsEvents() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(
            name: .signature,
            id: 1,
            config: DJPageConfig(information: "I agree", titleText: "Sign here")
        )
        preference.DJSteps = [
            TestFixtures.authStep(name: .signature, id: 1),
            TestFixtures.authStep(name: .index, id: 2)
        ]
        let events = MockEventsRemoteDatasource()
        let sut = SignatureViewModel(eventsRemoteDatasource: events, preference: preference)
        XCTAssertEqual(sut.signatureTitle, "Sign here")
        XCTAssertEqual(sut.signatureInformation, "I agree")

        sut.didTapPrimaryButton(name: "Ada", signatureData: Data("sig".utf8))
        XCTAssertEqual(events.postedEvents.first?.name, .signature)
        XCTAssertTrue(events.postedEvents.first?.value.contains("Ada") ?? false)
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted })
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.id, 2)

        events.postEventResult = .failure(.tryAgain)
        var message: FeedbackConfig?
        sut.showMessage = { message = $0 }
        sut.confirm(name: "Ada", signatureData: Data())
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepFailed })
        XCTAssertNotNil(message)
    }

    func testCustomQuestionsLoadAndSubmit() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(
            name: .customQuestions,
            id: 1,
            config: DJPageConfig(
                questions: [
                    DJPageQuestion(text: "Color?", type: "single", options: ["Red", "Blue"]),
                    DJPageQuestion(text: "Bio", type: "text", options: nil),
                    DJPageQuestion(text: "bad", type: "unknown", options: nil)
                ],
                titleText: "Questions"
            )
        )
        preference.DJSteps = [
            TestFixtures.authStep(name: .customQuestions, id: 1),
            TestFixtures.authStep(name: .index, id: 2)
        ]
        let events = MockEventsRemoteDatasource()
        let view = MockCustomQuestionsView()
        let sut = CustomQuestionsViewModel(eventsRemoteDatasource: events, preference: preference)
        sut.viewProtocol = view
        XCTAssertEqual(sut.questionsConfig.title, "Questions")
        XCTAssertEqual(sut.questionsConfig.questions.count, 2)
        XCTAssertEqual(sut.makeConfig().questions.first?.type, .single)

        sut.updateSubmitAvailability(allAnswered: true)
        XCTAssertEqual(view.submitEnabled, true)

        let answers = [
            CustomQuestionsResult.AnsweredQuestion(text: "Color?", type: .single, options: ["Red"], answer: .single("Red"))
        ]
        sut.didTapPrimaryButton(answered: answers)
        waitForMainQueue()
        XCTAssertEqual(events.postedCustomQuestions.first?.name, "questions")
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted })
        XCTAssertEqual(preference.DJAuthStep.id, 2)

        events.postCustomQuestionsResult = .failure(.tryAgain)
        var message: FeedbackConfig?
        sut.showMessage = { message = $0 }
        sut.submit(answered: answers)
        waitForMainQueue()
        XCTAssertEqual(message?.message, DJSDKError.tryAgain.uiMessage)
    }

    func testCustomQuestionsIgnoresNonCustomStep() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .email)
        let sut = CustomQuestionsViewModel(preference: preference)
        XCTAssertEqual(sut.questionsConfig.questions.count, 0)
        XCTAssertEqual(sut.questionsConfig.title, "")
    }

    func testUserDataSaveSuccessAndFailure() {
        let preference = MockPreference()
        preference.DJCountryCode = "NG"
        preference.DJAuthStep = TestFixtures.authStep(name: .userData, id: 3)
        preference.DJSteps = [
            TestFixtures.authStep(name: .userData, id: 3),
            TestFixtures.authStep(name: .email, id: 4)
        ]
        let remote = MockUserDataRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let view = MockUserDataView()
        let sut = UserDataViewModel(
            remoteDatasource: remote,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view

        sut.saveUserData(firstName: "Ada", middleName: "King", lastName: "Lovelace", dob: "01-01-1990")
        waitForMainQueue()
        XCTAssertEqual(remote.lastParams?["first_name"] as? String, "Ada")
        XCTAssertEqual(remote.lastParams?["country"] as? String, "NG")
        XCTAssertEqual(remote.lastParams?["step_number"] as? Int, 3)
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted })
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .email)

        var failed = false
        remote.result = .success(TestFixtures.successResponse(success: false, msg: "nope"))
        sut.saveUserData(firstName: "Ada", lastName: "Lovelace", dob: "01-01-1990") { failed = true }
        waitForMainQueue()
        XCTAssertTrue(failed)
        XCTAssertEqual(view.shownError, "nope")
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepFailed })

        remote.result = .failure(.serverFailure)
        sut.saveUserData(firstName: "Ada", lastName: "Lovelace", dob: "01-01-1990")
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.serverFailure.uiMessage)
    }
}
