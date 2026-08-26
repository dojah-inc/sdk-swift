import XCTest
@testable import DojahWidget

final class RemoteDatasourceTests: XCTestCase {
    func testEventsRemoteDatasourcePostsExpectedPath() {
        let network = MockNetworkService()
        network.handler = { _ in DJResult<SuccessEntityResponse>.success(TestFixtures.successResponse()) }
        let sut = EventsRemoteDatasource(service: network)
        let expectation = expectation(description: "events")
        sut.postEvent(request: .event(name: .stepCompleted, pageName: .email)) { result in
            XCTAssertNotNil(try? result.get())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(network.lastMethod, .post)
        XCTAssertEqual(network.lastPath, .events)
        XCTAssertEqual(network.lastParameters?["event_type"] as? String, "step_completed")
    }

    func testOTPRemoteDatasourceRequestAndValidate() {
        let network = MockNetworkService()
        network.handler = { type in
            if type == EntityResponse<[OTPRequestResponse]>.self {
                return DJResult<EntityResponse<[OTPRequestResponse]>>.success(EntityResponse(entity: []))
            }
            return DJResult<EntityResponse<OTPValidationResponse>>.success(
                EntityResponse(entity: OTPValidationResponse(valid: true))
            )
        }
        let sut = OTPRemoteDatasource(service: network)
        sut.requestOTP(params: ["email": "a@b.com"]) { _ in }
        XCTAssertEqual(network.lastPath, .requestOTP)
        XCTAssertEqual(network.lastMethod, .post)

        sut.validateOTP(params: ["code": "1234"]) { _ in }
        XCTAssertEqual(network.lastPath, .validateOTP)
        XCTAssertEqual(network.lastMethod, .get)
    }

    func testGovernmentDataLookupUsesIDTypePath() {
        let network = MockNetworkService()
        network.handler = { _ in
            DJResult<EntityResponse<GovernmentDataLookupEntity>>.success(EntityResponse(entity: TestFixtures.lookupEntity()))
        }
        let sut = GovernmentDataRemoteDatasource(service: network)
        sut.lookupID(number: "222", idType: .nin) { _ in }
        XCTAssertEqual(network.lastPath, .ninLookup)
        XCTAssertEqual(network.lastMethod, .get)
        XCTAssertEqual(network.lastParameters?["nin"] as? String, "222")
    }

    func testBusinessUserAddressLivenessAuthAndDecisionDatasources() {
        let network = MockNetworkService()
        network.handler = { type in
            if type == SuccessEntityResponse.self {
                return DJResult<SuccessEntityResponse>.success(TestFixtures.successResponse())
            }
            if type == EntityResponse<BusinessDataResponse>.self {
                return DJResult<EntityResponse<BusinessDataResponse>>.success(EntityResponse(entity: nil))
            }
            if type == DJPreAuthResponse.self {
                return DJResult<DJPreAuthResponse>.success(DJPreAuthResponse(widget: nil, publicKey: nil, appConfig: nil))
            }
            if type == DJAuthResponse.self {
                return DJResult<DJAuthResponse>.success(DJAuthResponse(
                    companyName: nil, initData: nil, appConfig: nil, sessionID: nil, environment: nil, whiteLabel: nil, ucode: nil
                ))
            }
            if type == DJIPAddress.self {
                return DJResult<DJIPAddress>.success(DJIPAddress(ip: "1.1.1.1"))
            }
            if type == DJIPAddressResponse.self {
                return DJResult<DJIPAddressResponse>.success(DJIPAddressResponse(entity: nil))
            }
            if type == EntityResponse<DecisionResponse>.self {
                return DJResult<EntityResponse<DecisionResponse>>.success(EntityResponse(entity: nil))
            }
            if type == EntityResponse<ImageAnalysisResponse>.self {
                return DJResult<EntityResponse<ImageAnalysisResponse>>.success(EntityResponse(entity: nil))
            }
            if type == EntityResponse<ImageCheckResponse>.self {
                return DJResult<EntityResponse<ImageCheckResponse>>.success(EntityResponse(entity: nil))
            }
            if type == EntityResponse<ImageVerificationResponse>.self {
                return DJResult<EntityResponse<ImageVerificationResponse>>.success(EntityResponse(entity: nil))
            }
            return DJResult<SuccessEntityResponse>.success(TestFixtures.successResponse())
        }

        BusinessDataRemoteDatasource(service: network).verify(type: .tin, params: ["tin": "1"]) { _ in }
        XCTAssertEqual(network.lastPath, .tin)

        UserDataRemoteDatasource(service: network).saveUserData(params: ["first_name": "Ada"]) { _ in }
        XCTAssertEqual(network.lastPath, .userData)
        XCTAssertEqual(network.lastMethod, .post)

        AddressVerificationRemoteDatasource(service: network).sendAddress(type: .userLocation, params: [:]) { _ in }
        XCTAssertEqual(network.lastPath, .address)

        AddressVerificationRemoteDatasource(service: network).sendAddress(type: .userSelected, params: [:]) { _ in }
        XCTAssertEqual(network.lastPath, .baseAddress)

        let liveness = LivenessRemoteDatasource(service: network)
        liveness.performImageAnalysis(params: [:]) { _ in }
        XCTAssertEqual(network.lastPath, .imageAnalysis)
        liveness.performImageCheck(params: [:]) { _ in }
        XCTAssertEqual(network.lastPath, .imageCheck)
        liveness.verifyImage(params: [:]) { _ in }
        XCTAssertEqual(network.lastPath, .verifyImage)
        liveness.uploadDocument(params: [:]) { _ in }
        XCTAssertEqual(network.lastPath, .files)

        let auth = AuthenticationRemoteDatasource(service: network)
        auth.getPreAuthenticationInfo(params: ["widget_id": "x"]) { _ in }
        XCTAssertEqual(network.lastPath, .preAuth)
        XCTAssertEqual(network.lastMethod, .get)
        auth.authenticate(params: [:]) { _ in }
        XCTAssertEqual(network.lastPath, .auth)
        XCTAssertEqual(network.lastMethod, .post)
        XCTAssertNotNil(network.lastHeaders?["Authorization"])
        auth.getIPAddress { _ in }
        XCTAssertEqual(network.lastPath, .ipCheck)
        auth.saveIPAddress(params: ["ip": "1"]) { _ in }
        XCTAssertEqual(network.lastPath, .saveIP)

        DecisionEngineRemoteDatasource(service: network).makeVerificationDecision { _ in }
        XCTAssertEqual(network.lastPath, .decision)
        XCTAssertEqual(network.lastMethod, .get)

        MetaDataRemoteDatasource(service: network).sendMetaData(params: ["meta": "x"]) { _ in }
        XCTAssertEqual(network.lastPath, .metadata)
    }

    func testEventsEmailAndCustomQuestionVariants() {
        let network = MockNetworkService()
        network.handler = { type in
            if type == EntityResponse<EmailCollectedEventResponse>.self {
                return DJResult<EntityResponse<EmailCollectedEventResponse>>.success(EntityResponse(entity: nil))
            }
            return DJResult<SuccessEntityResponse>.success(TestFixtures.successResponse())
        }
        let sut = EventsRemoteDatasource(service: network)
        sut.postEmailCollectedEvent(request: .init(name: .emailCollected, value: "x")) { _ in }
        XCTAssertEqual(network.lastPath, .events)
        sut.postCustomQuestionsEvent(request: .init(value: [])) { _ in }
        XCTAssertEqual(network.lastParameters?["event_type"] as? String, "questions")
    }
}
