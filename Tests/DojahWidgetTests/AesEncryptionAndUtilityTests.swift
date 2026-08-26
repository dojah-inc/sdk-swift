import XCTest
@testable import DojahWidget

final class AesEncryptionAndUtilityTests: XCTestCase {
    func testEncryptProducesBase64AndIsDeterministic() {
        let first = AesEncryption.encrypt(data: "hello", secret: "6543210987654321")
        let second = AesEncryption.encrypt(data: "hello", secret: "6543210987654321")
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, "hello")
        XCTAssertNotNil(Data(base64Encoded: first))
    }

    func testEncryptStripsDataURLPrefix() {
        let raw = AesEncryption.encrypt(data: "payload", secret: "6543210987654321")
        let jpeg = AesEncryption.encrypt(data: "data:image/jpeg;base64,payload", secret: "6543210987654321")
        let png = AesEncryption.encrypt(data: "data:image/png;base64,payload", secret: "6543210987654321")
        let pdf = AesEncryption.encrypt(data: "data:application/pdf;base64,payload", secret: "6543210987654321")
        XCTAssertEqual(raw, jpeg)
        XCTAssertEqual(raw, png)
        XCTAssertEqual(raw, pdf)
    }

    func testEncryptEmptyStringStillReturnsValue() {
        let encrypted = AesEncryption.encrypt(data: "", secret: "6543210987654321")
        XCTAssertFalse(encrypted.isEmpty)
        XCTAssertNotNil(Data(base64Encoded: encrypted))
    }

    func testDJRemotePathAbsolutePaths() {
        XCTAssertEqual(DJRemotePath.none.path, "")
        XCTAssertEqual(DJRemotePath.preAuth.path, "widget/pre-auth")
        XCTAssertEqual(DJRemotePath.auth.path, "widget/auth")
        XCTAssertEqual(DJRemotePath.events.path, "widget/kyc/events")
        XCTAssertEqual(DJRemotePath.bvnAdvanceLookup.path, "widget/kyc/bvn/advance")
        XCTAssertEqual(DJRemotePath.decision.path, "widget/decision")
        XCTAssertEqual(DJRemotePath.metadata.path, "widget/kyc/metadata")
        XCTAssertEqual(DJRemotePath.cac.absolutePath, "https://api.dojah.io/widget/kyc/cac")
        XCTAssertTrue(DJRemotePath.none.absolutePath.hasSuffix("/"))
    }

    func testDJHttpMethodRawValues() {
        XCTAssertEqual(DJHttpMethod.get.rawValue, "GET")
        XCTAssertEqual(DJHttpMethod.post.rawValue, "POST")
        XCTAssertEqual(DJHttpMethod.put.rawValue, "PUT")
        XCTAssertEqual(DJHttpMethod.delete.rawValue, "DELETE")
    }

    func testURLSessionTimeout() {
        let session = URLSession.withTimeout(12)
        XCTAssertEqual(session.configuration.timeoutIntervalForRequest, 12)
    }

    func testDJConstants() {
        XCTAssertEqual(DJConstants.dateFormat, "dd-MM-yyyy")
        XCTAssertEqual(DJConstants.monthNames.count, 12)
        XCTAssertEqual(DJConstants.monthDays.count, 31)
        XCTAssertEqual(DJConstants.monthDays.first, 1)
        XCTAssertFalse(DJConstants.years.isEmpty)
        XCTAssertEqual(DJConstants.disclaimerItems.count, 3)
        XCTAssertEqual(DJConstants.idCaptureDisclaimerItems.count, 3)
        XCTAssertEqual(DJConstants.selfieCaptureDisclaimerItems.count, 3)
        XCTAssertEqual(DJConstants.locationDisclaimerItems.count, 4)
        XCTAssertEqual(DJConstants.genericErrorMessage, DJSDKError.tryAgain.uiMessage)
    }

    func testDojahDeviceIdReturnsUUID() {
        let id = DojahDeviceId.get()
        XCTAssertFalse(id.isEmpty)
        XCTAssertNotNil(UUID(uuidString: id))
    }

    func testURLLocalFileData() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("dojah-test.txt")
        try Data("hello".utf8).write(to: url)
        XCTAssertEqual(url.localFileData, Data("hello".utf8))
        let missing = URL(fileURLWithPath: "/tmp/does-not-exist-dojah-\(UUID().uuidString)")
        XCTAssertNil(missing.localFileData)
    }
}
