import CoreLocation
import XCTest
@testable import DojahWidget

final class CaptureAddressAndSDKInitViewModelTests: XCTestCase {
    func testAddressFilterProvincesAndMissingPlace() {
        let preference = MockPreference()
        preference.DJIPCountry = "NG"
        preference.DJCountryStates = [TestFixtures.homeCountry()]
        let view = MockAddressView()
        let remote = MockAddressVerificationRemoteDatasource()
        let sut = AddressVerificationViewModel(
            remoteDatasource: remote,
            preference: preference
        )
        sut.viewProtocol = view
        XCTAssertEqual(sut.states.map(\.name), ["Lagos", "Abuja"])

        sut.onStateSelected(0)
        XCTAssertEqual(sut.provinces, ["Ikeja", "Lekki", "Surulere"])
        sut.filterProvinces("lek")
        waitForMainQueue()
        XCTAssertEqual(sut.filteredProvinces, ["Lekki"])
        XCTAssertTrue(view.showProvincesCalled)

        sut.filterProvinces("")
        waitForMainQueue()
        XCTAssertEqual(sut.filteredProvinces, ["Ikeja", "Lekki", "Surulere"])

        sut.didTapContinue(lga: "Ikeja")
        waitForMainQueue()
        XCTAssertEqual(view.shownError, "Choose a valid address")

        sut.currentLocation = nil
        sut.sendManualAddress(address: "12 Broad", lga: "Ikeja")
        waitForMainQueue()
        XCTAssertEqual(view.shownError, "No valid address is passed")
    }

    func testAddressSendManualSuccessAndFailure() {
        let preference = MockPreference()
        preference.DJIPCountry = "NG"
        preference.DJCountryStates = [TestFixtures.homeCountry()]
        preference.DJAuthStep = TestFixtures.authStep(name: .address, id: 1, config: DJPageConfig(verification: false))
        preference.DJSteps = [
            TestFixtures.authStep(name: .address, id: 1),
            TestFixtures.authStep(name: .email, id: 2)
        ]
        let remote = MockAddressVerificationRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let view = MockAddressView()
        let sut = AddressVerificationViewModel(
            remoteDatasource: remote,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view
        sut.onStateSelected(0)
        sut.currentLocation = CLLocation(latitude: 6.4, longitude: 3.4)
        sut.sendManualAddress(address: "12 Broad Street", lga: "Ikeja", landmark: "Shop")

        XCTAssertEqual(remote.lastType, .userSelected)
        XCTAssertEqual(remote.lastParams?["name"] as? String, "12 Broad Street")
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted })
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .email)

        remote.result = .success(TestFixtures.successResponse(success: false, msg: "bad address"))
        sut.sendManualAddress(address: "12 Broad Street", lga: "Ikeja")
        waitForMainQueue()
        XCTAssertEqual(view.shownError, "bad address")

        remote.result = .failure(.tryAgain)
        sut.sendManualAddress(address: "12 Broad Street", lga: "Ikeja")
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.tryAgain.uiMessage)
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepFailed })
    }

    func testGovtIDCaptureInitialStateAndImageUpdates() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .id)
        let frontBackID = TestFixtures.governmentID(name: "National ID", value: "NATIONAL_ID")
        let view = MockGovtIDCaptureView()
        let liveness = MockLivenessRemoteDatasource()
        let sut = GovtIDCaptureViewModel(
            selectedID: frontBackID,
            livenessRemoteDatasource: liveness,
            preference: preference
        )
        sut.viewProtocol = view
        XCTAssertEqual(sut.viewState, .captureFront)
        XCTAssertEqual(sut.idName, "National ID")
        XCTAssertFalse(sut.isDocumentUpload)

        let image = Data("front".utf8)
        sut.updateImageData(image)
        XCTAssertEqual(sut.idFrontImageData, image)

        sut.updateViewState()
        waitForMainQueue()
        XCTAssertEqual(sut.viewState, .previewFront)
        XCTAssertTrue(view.updateUICalled)

        sut.viewState = .captureBack
        sut.updateImageData(Data("back".utf8))
        XCTAssertEqual(sut.idBackImageData, Data("back".utf8))
    }

    func testGovtIDCaptureBusinessAndAdditionalDocumentStates() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .businessID)
        let sut = GovtIDCaptureViewModel(
            selectedID: TestFixtures.governmentID(name: "CAC"),
            preference: preference
        )
        XCTAssertEqual(sut.viewState, .captureCACDocument)
        XCTAssertEqual(sut.idName, "CAC Document")

        preference.DJAuthStep = TestFixtures.authStep(name: .additionalDocument)
        let additional = GovtIDCaptureViewModel(preference: preference)
        XCTAssertEqual(additional.viewState, .captureDocument)

        additional.viewState = .uploadDocument
        XCTAssertTrue(additional.isDocumentUpload)
    }

    func testGovtIDCaptureContinueWithoutImageAndSuccessfulCheck() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .id, id: 1)
        preference.DJSteps = [
            TestFixtures.authStep(name: .id, id: 1),
            TestFixtures.authStep(name: .email, id: 2)
        ]
        let liveness = MockLivenessRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let view = MockGovtIDCaptureView()
        let sut = GovtIDCaptureViewModel(
            selectedID: TestFixtures.governmentID(name: "Passport", value: "NG-PASS"),
            livenessRemoteDatasource: liveness,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view
        sut.viewState = .previewFront
        sut.didTapContinue()
        XCTAssertNil(liveness.checkParams)

        sut.updateImageData(Data("img".utf8))
        sut.didTapContinue()
        XCTAssertNotNil(liveness.checkParams)
        XCTAssertEqual(liveness.checkParams?["param"] as? String, "NG-PASS")
        XCTAssertNotNil(liveness.verifyParams)
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepCompleted })
        waitForRunAfter()
        XCTAssertEqual(preference.DJAuthStep.name, .email)
    }

    func testGovtIDCaptureCheckMismatchAndUploadFailure() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .id, id: 1)
        preference.DJSteps = [TestFixtures.authStep(name: .id, id: 1)]
        let liveness = MockLivenessRemoteDatasource()
        liveness.checkResult = .success(EntityResponse(entity: ImageCheckResponse(match: false, reason: "blurry", continueVerification: false)))
        let events = MockEventsRemoteDatasource()
        let view = MockGovtIDCaptureView()
        let sut = GovtIDCaptureViewModel(
            selectedID: TestFixtures.governmentID(name: "NIN Slip", value: "NG-NIN-SLIP"),
            livenessRemoteDatasource: liveness,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.viewProtocol = view
        sut.viewState = .previewFront
        sut.updateImageData(Data("img".utf8))
        sut.didTapContinue()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, "blurry")

        liveness.checkResult = .failure(.imageCheckOrAnalysisError)
        sut.didTapContinue()
        waitForMainQueue()
        XCTAssertEqual(view.shownError, DJSDKError.govtIDCouldNotBeCaptured.uiMessage)
        XCTAssertTrue(events.postedEvents.contains { $0.name == .stepFailed })
    }

    func testGovtIDCaptureDownloadImageInvalidURL() {
        let sut = GovtIDCaptureViewModel()
        let expectation = expectation(description: "invalid-url")
        sut.downloadImageAndConvertToBase64(from: "not a url") { value in
            XCTAssertNil(value)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testUtilityBillViewStateTransitions() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .address)
        let view = MockUtilityBillView()
        let liveness = MockLivenessRemoteDatasource()
        let sut = UtilityBillViewModel(livenessRemoteDatasource: liveness, preference: preference)
        sut.viewProtocol = view
        XCTAssertEqual(sut.viewState, .capture)
        XCTAssertFalse(sut.isDocumentUpload)

        sut.updateViewState()
        waitForMainQueue()
        XCTAssertEqual(sut.viewState, .preview)
        XCTAssertTrue(view.updateUICalled)

        sut.viewState = .upload
        XCTAssertTrue(sut.isDocumentUpload)
        sut.updateImageData(Data("bill".utf8))
        XCTAssertEqual(sut.utilityBillImage, Data("bill".utf8))
        sut.didTapContinue()
        waitForMainQueue()
        XCTAssertEqual(sut.viewState, .upload)
    }

    func testSelfiePerformImageCheckRequiresImageAndSucceeds() {
        let preference = MockPreference()
        preference.DJAuthStep = TestFixtures.authStep(name: .governmentDataVerification, id: 1)
        preference.DJSteps = [
            TestFixtures.authStep(name: .governmentDataVerification, id: 1),
            TestFixtures.authStep(name: .email, id: 2)
        ]
        let remote = MockLivenessRemoteDatasource()
        let events = MockEventsRemoteDatasource()
        let sut = SelfieVideoKYCViewModel(
            remoteDatasource: remote,
            verificationMethod: .selfie,
            viewState: .previewSelfie,
            eventsRemoteDatasource: events,
            preference: preference
        )
        sut.performImageCheck()
        XCTAssertNil(remote.checkParams)

        sut.imageData = Data("face".utf8)
        sut.performImageCheck()
        XCTAssertEqual(remote.checkParams?["param"] as? String, "face")
        XCTAssertEqual(remote.checkParams?["selfie_type"] as? String, "single")
    }

    @MainActor
    func testSDKInitStoresWidgetMetadataAndFailsWithoutPages() async {
        let preference = MockPreference()
        let auth = MockAuthenticationRemoteDatasource()
        auth.preAuthResult = .success(DJPreAuthResponse(widget: DJWidget(
            published: true, reviewProcess: nil, pages: [], countries: ["NG"],
            env: nil, company: nil, duplicateCheck: nil, directFeedback: nil, rules: nil
        ), publicKey: "pk", appConfig: DJAppConfig(name: "App", logo: nil, colorCode: nil, id: "app-1")))
        let view = MockSDKInitView()
        let sut = SDKInitViewModel(
            widgetID: "wid-1",
            referenceID: "ref-1",
            emailAddress: "user@example.com",
            source: "ios_test",
            extraUserData: ExtraUserData(userData: UserBioData(firstName: "Ada")),
            preference: preference,
            countriesDatasource: MockCountriesLocalDatasource(),
            authenticationRemoteDatasource: auth,
            metadataRemoteDatasource: MockMetaDataRemoteDatasource()
        )
        sut.viewProtocol = view
        sut.initialize()

        XCTAssertEqual(preference.DJWidgetID, "wid-1")
        XCTAssertEqual(preference.platformSource, "ios_test")
        XCTAssertEqual(preference.preAuthEmailAddress, "user@example.com")
        XCTAssertEqual(preference.DJExtraUserData?.userData?.firstName, "Ada")
        XCTAssertTrue(view.failedShown)
        XCTAssertEqual(auth.preAuthParams?["widget_id"] as? String, "wid-1")
    }

    @MainActor
    func testSDKInitVerificationCompletedAndAuthFailure() async {
        let preference = MockPreference()
        preference.DJConfigurationInitialized = true
        let auth = MockAuthenticationRemoteDatasource()
        let widget = DJWidget(
            published: true,
            reviewProcess: "Automatic",
            pages: [TestFixtures.page(name: .email, config: DJPageConfig(verification: true))],
            countries: ["NG"],
            env: "prod",
            company: nil,
            duplicateCheck: false,
            directFeedback: false,
            rules: nil
        )
        auth.preAuthResult = .success(DJPreAuthResponse(
            widget: widget,
            publicKey: "pk",
            appConfig: DJAppConfig(name: "App", logo: nil, colorCode: nil, id: "app-1")
        ))
        auth.authResult = .failure(.verificationCompleted)
        let view = MockSDKInitView()
        let sut = SDKInitViewModel(
            widgetID: "wid",
            preference: preference,
            countriesDatasource: MockCountriesLocalDatasource(),
            authenticationRemoteDatasource: auth,
            metadataRemoteDatasource: MockMetaDataRemoteDatasource()
        )
        sut.viewProtocol = view
        sut.initialize()
        XCTAssertTrue(view.verificationSuccessfulShown)

        auth.authResult = .failure(.serverFailure)
        let view2 = MockSDKInitView()
        let sut2 = SDKInitViewModel(
            widgetID: "wid",
            preference: preference,
            countriesDatasource: MockCountriesLocalDatasource(),
            authenticationRemoteDatasource: auth,
            metadataRemoteDatasource: MockMetaDataRemoteDatasource()
        )
        sut2.viewProtocol = view2
        sut2.initialize()
        XCTAssertTrue(view2.failedShown)
    }

    @MainActor
    func testSDKInitHappyPathShowsDisclaimer() async {
        let preference = MockPreference()
        preference.DJConfigurationInitialized = true
        let auth = MockAuthenticationRemoteDatasource()
        let widget = DJWidget(
            published: true,
            reviewProcess: "Automatic",
            pages: [
                TestFixtures.page(name: .email),
                TestFixtures.page(name: .userData),
                TestFixtures.page(name: .governmentData, config: DJPageConfig(bvn: true, otp: true, selfie: true)),
                TestFixtures.page(name: .id)
            ],
            countries: ["NG"],
            env: "prod",
            company: nil,
            duplicateCheck: true,
            directFeedback: false,
            rules: nil
        )
        auth.preAuthResult = .success(DJPreAuthResponse(
            widget: widget,
            publicKey: "pk",
            appConfig: DJAppConfig(name: "App", logo: nil, colorCode: nil, id: "app-1")
        ))
        auth.authResult = .success(DJAuthResponse(
            companyName: "Dojah",
            initData: DJInitData(
                success: true,
                msg: "ok",
                data: DJInitDataConfig(
                    verificationID: 44,
                    steps: [TestFixtures.authStep(name: .email, id: 1, status: .notdone)],
                    stepNumber: 1,
                    referenceID: "ref",
                    sessionID: "sess",
                    verificationTypeSelected: nil
                )
            ),
            appConfig: DJAppConfig(name: "App", logo: nil, colorCode: nil, id: "app-1"),
            sessionID: "sess",
            environment: "prod",
            whiteLabel: false,
            ucode: nil
        ))
        auth.ipResult = .success(DJIPAddress(ip: "8.8.8.8"))
        let entity: DJIPAddressEntity = TestFixtures.decode(#"{"country":"Nigeria","countryCode":"NG"}"#)
        auth.saveIPResult = .success(DJIPAddressResponse(entity: entity))
        let countries = MockCountriesLocalDatasource()
        let view = MockSDKInitView()
        let sut = SDKInitViewModel(
            widgetID: "wid-9",
            emailAddress: "a@b.com",
            extraUserData: ExtraUserData(metadata: ["k": "v"]),
            preference: preference,
            countriesDatasource: countries,
            authenticationRemoteDatasource: auth,
            metadataRemoteDatasource: MockMetaDataRemoteDatasource()
        )
        sut.viewProtocol = view
        let disclaimer = expectation(description: "disclaimer")
        view.onDisclaimer = { disclaimer.fulfill() }
        sut.initialize()
        await fulfillment(of: [disclaimer], timeout: 2)

        XCTAssertEqual(preference.DJVerificationID, 44)
        XCTAssertEqual(preference.DJRequestHeaders["app-id"], "app-1")
        XCTAssertEqual(preference.DJIPCountry, "NG")
        XCTAssertTrue(view.disclaimerShown)
        XCTAssertEqual(auth.saveIPParams?["ip"] as? String, "8.8.8.8")
        XCTAssertTrue(preference.WidgetIDCache.contains { $0.widgetID == "wid-9" })
    }

    @MainActor
    func testSDKInitCountryNotSupported() async {
        let preference = MockPreference()
        preference.DJConfigurationInitialized = true
        let auth = MockAuthenticationRemoteDatasource()
        let widget = DJWidget(
            published: true, reviewProcess: nil,
            pages: [TestFixtures.page(name: .email)],
            countries: ["KE"], env: nil, company: nil,
            duplicateCheck: nil, directFeedback: nil, rules: nil
        )
        auth.preAuthResult = .success(DJPreAuthResponse(
            widget: widget, publicKey: "pk",
            appConfig: DJAppConfig(name: "App", logo: nil, colorCode: nil, id: "app")
        ))
        auth.authResult = .success(DJAuthResponse(
            companyName: "Dojah",
            initData: DJInitData(success: true, msg: nil, data: DJInitDataConfig(
                verificationID: 1, steps: [], stepNumber: 0, referenceID: "r", sessionID: "s", verificationTypeSelected: nil
            )),
            appConfig: nil, sessionID: "s", environment: nil, whiteLabel: nil, ucode: nil
        ))
        auth.ipResult = .success(DJIPAddress(ip: "1.1.1.1"))
        auth.saveIPResult = .success(DJIPAddressResponse(entity: TestFixtures.decode(#"{"country":"Nigeria"}"#)))
        let view = MockSDKInitView()
        let sut = SDKInitViewModel(
            widgetID: "wid",
            preference: preference,
            countriesDatasource: MockCountriesLocalDatasource(),
            authenticationRemoteDatasource: auth,
            metadataRemoteDatasource: MockMetaDataRemoteDatasource()
        )
        sut.viewProtocol = view
        let unsupported = expectation(description: "unsupported")
        view.onCountryNotSupported = { unsupported.fulfill() }
        sut.initialize()
        await fulfillment(of: [unsupported], timeout: 2)
        XCTAssertTrue(view.countryNotSupportedShown)
    }
}
