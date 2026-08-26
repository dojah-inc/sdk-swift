import XCTest
@testable import DojahWidget

final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))?
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        guard let handler = Self.handler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (status, data) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://api.dojah.io")!,
                statusCode: status,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class NetworkServiceTests: XCTestCase {
    private var preference: MockPreference!
    private var sut: NetworkService!

    override func setUp() {
        super.setUp()
        preference = MockPreference()
        preference.DJVerificationID = 77
        preference.DJAuthStep = TestFixtures.authStep(name: .email, id: 3)
        preference.DJRequestHeaders = ["app-id": "app", "session": "sess", "authorization": "token"]
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        sut = NetworkService(urlSession: URLSession(configuration: config), preference: preference)
        MockURLProtocol.handler = nil
        MockURLProtocol.lastRequest = nil
    }

    private func waitForRequest<T: Codable>(
        type: T.Type,
        method: DJHttpMethod = .get,
        path: DJRemotePath,
        parameters: DJParameters? = nil,
        headers: DJHeaderParameters? = nil
    ) -> DJResult<T> {
        let expectation = expectation(description: "network")
        var captured: DJResult<T>!
        sut.makeRequest(
            responseType: type,
            requestMethod: method,
            remotePath: path,
            parameters: parameters,
            headers: headers
        ) { result in
            captured = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2)
        return captured
    }

    private func assertFailure<T>(_ result: DJResult<T>, _ expected: DJSDKError, file: StaticString = #filePath, line: UInt = #line) {
        guard case .failure(let error) = result else {
            XCTFail("Expected failure \(expected), got \(result)", file: file, line: line)
            return
        }
        XCTAssertEqual(error, expected, file: file, line: line)
    }

    func testSuccessfulDecode() {
        MockURLProtocol.handler = { _ in (200, Data(#"{"ip":"1.2.3.4"}"#.utf8)) }
        let result = waitForRequest(type: DJIPAddress.self, path: .ipCheck)
        XCTAssertEqual(try? result.get().ip, "1.2.3.4")
    }

    func testGetAddsQueryItemsAndDecisionParams() {
        MockURLProtocol.handler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("verification_id=77") ?? false)
            XCTAssertTrue(request.url?.absoluteString.contains("session_id=sess") ?? false)
            return (200, Data(#"{"entity":null}"#.utf8))
        }
        _ = waitForRequest(type: EntityResponse<DecisionResponse>.self, path: .decision)
    }

    func testCacAppendsAppIdQueryItem() {
        MockURLProtocol.handler = { request in
            XCTAssertTrue(request.url?.absoluteString.contains("app_id=app") ?? false)
            return (200, Data(#"{"entity":null}"#.utf8))
        }
        _ = waitForRequest(
            type: EntityResponse<BusinessDataResponse>.self,
            path: .cac,
            parameters: ["rc_number": "1"]
        )
    }

    func testPostMergesVerificationAndEventFields() throws {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertTrue(request.url?.absoluteString.contains("widget/kyc/events") ?? false)
            XCTAssertEqual(request.value(forHTTPHeaderField: "app-id"), "app")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            return (200, Data(#"{"entity":{"success":true}}"#.utf8))
        }
        let result = waitForRequest(
            type: SuccessEntityResponse.self,
            method: .post,
            path: .events,
            parameters: ["event_type": "step_completed"]
        )
        XCTAssertEqual(try? result.get().entity?.success, true)
    }

    func testStatusCodeMappings() {
        MockURLProtocol.handler = { _ in (402, Data()) }
        assertFailure(waitForRequest(type: DJIPAddress.self, path: .auth), .verificationCompleted)

        MockURLProtocol.handler = { _ in (402, Data()) }
        assertFailure(waitForRequest(type: DJIPAddress.self, path: .ipCheck), .lowBalance)

        MockURLProtocol.handler = { _ in (424, Data()) }
        assertFailure(waitForRequest(type: DJIPAddress.self, path: .bvnLookup), .invalidIDThirdPartyFailure)

        MockURLProtocol.handler = { _ in (424, Data()) }
        assertFailure(waitForRequest(type: DJIPAddress.self, path: .ipCheck), .serverFailure)

        MockURLProtocol.handler = { _ in (404, Data()) }
        assertFailure(waitForRequest(type: DJIPAddress.self, path: .ninLookup), .invalidIDNotFoundThirdParty)

        MockURLProtocol.handler = { _ in (400, Data()) }
        assertFailure(waitForRequest(type: DJIPAddress.self, path: .events), .resourceNotFound)

        MockURLProtocol.handler = { _ in (500, Data()) }
        assertFailure(waitForRequest(type: DJIPAddress.self, path: .ipCheck), .serverFailure)

        MockURLProtocol.handler = { _ in (201, Data()) }
        assertFailure(waitForRequest(type: DJIPAddress.self, path: .imageCheck), .imageCheckOrAnalysisError)

        MockURLProtocol.handler = { _ in (201, Data()) }
        assertFailure(waitForRequest(type: DJIPAddress.self, path: .files), .govtIDCouldNotBeCaptured)
    }

    func testNetworkErrorPayloadAndDecodingFailure() {
        MockURLProtocol.handler = { _ in
            (200, Data(#"{"error":{"message":"nope","code":400,"success":false}}"#.utf8))
        }
        assertFailure(
            waitForRequest(type: DJIPAddress.self, path: .ipCheck),
            .networkError("nope")
        )

        MockURLProtocol.handler = { _ in
            (200, Data(#"{"error":{"message":"done","code":402,"success":false}}"#.utf8))
        }
        assertFailure(
            waitForRequest(type: DJAuthResponse.self, method: .post, path: .auth, parameters: [:]),
            .networkError("done")
        )

        MockURLProtocol.handler = { _ in (200, Data("not-json".utf8)) }
        switch waitForRequest(type: DJIPAddress.self, path: .ipCheck) {
        case .failure(.decodingFailure):
            break
        default:
            XCTFail("Expected decoding failure")
        }
    }

    func testCustomHeadersApplied() {
        MockURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Test"), "yes")
            return (200, Data(#"{"ip":"9.9.9.9"}"#.utf8))
        }
        _ = waitForRequest(
            type: DJIPAddress.self,
            path: .ipCheck,
            headers: ["X-Test": "yes"]
        )
    }
}
