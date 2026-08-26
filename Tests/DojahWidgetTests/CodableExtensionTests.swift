import XCTest
@testable import DojahWidget

private struct SamplePayload: Codable, Equatable {
    let name: String
    let count: Int
}

final class CodableExtensionTests: XCTestCase {
    func testEncodableJsonDictionaryAndPrettyJson() {
        let payload = SamplePayload(name: "Ada", count: 2)
        XCTAssertTrue(payload.jsonString.contains("Ada"))
        XCTAssertEqual(payload.dictionary["name"] as? String, "Ada")
        XCTAssertEqual(payload.dictionary["count"] as? Int, 2)
        XCTAssertTrue(payload.prettyJson.contains("Ada"))
        XCTAssertNotNil(payload.encodedData())
        XCTAssertTrue(payload.dictionaryValue is [String: Any])
    }

    func testEncodableArrayDictionaryArray() {
        let payloads = [SamplePayload(name: "A", count: 1), SamplePayload(name: "B", count: 2)]
        XCTAssertEqual(payloads.dictionaryArray.count, 2)
        XCTAssertEqual(payloads.dictionaryArray.first?["name"] as? String, "A")
    }

    func testDecodableMapFromJsonString() throws {
        let decoded = try SamplePayload.mapFrom(jsonString: #"{"name":"Ada","count":3}"#)
        XCTAssertEqual(decoded, SamplePayload(name: "Ada", count: 3))
        XCTAssertThrowsError(try SamplePayload.mapFrom(jsonString: "not-json"))
    }

    func testDataDecodeAndPrettyJson() throws {
        let data = try JSONEncoder().encode(SamplePayload(name: "Ada", count: 1))
        XCTAssertEqual(try data.decode(into: SamplePayload.self), SamplePayload(name: "Ada", count: 1))
        XCTAssertTrue(try data.prettyJson().contains("Ada"))
    }

    func testDictionaryPrettyJsonAndSerializedData() throws {
        let dict = ["ok": true]
        XCTAssertFalse(dict.prettyJson.isEmpty)
        XCTAssertFalse(try dict.serializedData().isEmpty)
    }

    func testJsonDataFromKnownResource() {
        XCTAssertNotNil(jsonData(from: "countries"))
        XCTAssertNil(jsonData(from: "this_file_does_not_exist"))
    }

    func testEmptyCodableRoundTrip() throws {
        let data = try JSONEncoder().encode(EmptyCodable())
        XCTAssertNoThrow(try JSONDecoder().decode(EmptyCodable.self, from: data))
    }
}
