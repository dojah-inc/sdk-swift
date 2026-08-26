import XCTest
@testable import DojahWidget

final class StringExtensionTests: XCTestCase {
    func testIsNumber() {
        XCTAssertTrue("123".isNumber)
        XCTAssertTrue("0".isNumber)
        XCTAssertTrue("".isNumber)
        XCTAssertFalse("12a".isNumber)
        XCTAssertFalse("12.3".isNumber)
        XCTAssertTrue("12a".isNotNumber)
    }

    func testChunkFormatted() {
        XCTAssertEqual("12345678".chunkFormatted(), "1234 5678")
        XCTAssertEqual("123456789".chunkFormatted(withChunkSize: 3, withSeparator: "-"), "123-456-789")
        XCTAssertEqual("12 34".chunkFormatted(withChunkSize: 2), "12 34")
        XCTAssertEqual("".chunkFormatted(), "")
    }

    func testFormatWith234AndRemove234() {
        XCTAssertEqual("0803".formatWith234(), "+234803")
        XCTAssertEqual("+2348012345678".remove234, "08012345678")
        XCTAssertEqual("0803".remove234, "0803")
    }

    func testRemovePhoneCode_prefixes() {
        XCTAssertEqual("2348012345678".removePhoneCode(), "8012345678")
        XCTAssertEqual("233201234567".removePhoneCode(), "201234567")
        XCTAssertEqual("254712345678".removePhoneCode(), "712345678")
        XCTAssertEqual("2250700000000".removePhoneCode(), "0700000000")
        XCTAssertEqual("256700000000".removePhoneCode(), "700000000")
        XCTAssertEqual("+2348012345678".removePhoneCode(), "8012345678")
        XCTAssertEqual("+233201".removePhoneCode(), "201")
        XCTAssertEqual("0803".removePhoneCode(), "0803")
    }

    func testReplaceFirstOccurrence() {
        XCTAssertEqual("banana".replaceFirstOccurrence(of: "na", with: "NA"), "baNAna")
        XCTAssertEqual("banana".replaceFirstOccurrence(of: "xyz", with: "NA"), "banana")
    }

    func testOrDashOrEmptyDropFirstIfZero() {
        XCTAssertEqual("".orDash, "-")
        XCTAssertEqual("hi".orDash, "hi")
        XCTAssertEqual("".orEmpty, "")
        XCTAssertEqual("hi".orEmpty, "hi")
        XCTAssertEqual("0123".dropFirstIfZero, "123")
        XCTAssertEqual("123".dropFirstIfZero, "123")
        XCTAssertEqual("".dropFirstIfZero, "")
    }

    func testNumericConversions() {
        XCTAssertEqual("42".int, 42)
        XCTAssertNil("x".int)
        XCTAssertEqual("1.5".float, 1.5)
        XCTAssertEqual("2.25".double, 2.25)
        XCTAssertNil("abc".double)
    }

    func testInsensitiveComparisons() {
        XCTAssertTrue("Nigeria".insensitiveEquals("nigeria"))
        XCTAssertTrue("NG".insensitiveNotEquals("KE"))
        XCTAssertTrue("Bank Verification".insensitiveContains("verif"))
        XCTAssertTrue("Bank".insensitiveNotContains("xyz"))
    }

    func testSanitizationHelpers() {
        XCTAssertEqual("1,000".commasRemoved, "1000")
        XCTAssertEqual("1 000".spacesRemoved, "1000")
        XCTAssertEqual("12-34".dashesRemoved, "1234")
        XCTAssertEqual("  hi \n".whitespacesAndBNewlinesRemoved, "hi")
        XCTAssertEqual(" a b ".whitespacesAndNewlinesRemoved, "ab")
        XCTAssertEqual("A1B2".digitsRemoved, "AB")
        XCTAssertEqual("1,000".amountSanitized, "1000")
        XCTAssertEqual("$ 1,000".amountSanitized(symbol: "$"), "1000")
        XCTAssertEqual("ngn".currencySignRemoved, "ngn")
    }

    func testCamelAndKebabCase() {
        XCTAssertTrue("userName".isCamelCase)
        XCTAssertFalse("UserName".isCamelCase)
        XCTAssertFalse("user-name".isCamelCase)
        XCTAssertEqual("userName".toKebabCase(), "user-name")
        XCTAssertEqual("httpStatusCode".toKebabCase(), "http-status-code")
        XCTAssertEqual("UserName".toKebabCase(), "UserName")
        XCTAssertEqual("already-kebab".toKebabCase(), "already-kebab")
    }

    func testEncryptedUsesAes() {
        let value = "hello-world"
        XCTAssertEqual(value.encrypted(), AesEncryption.encrypt(data: value, secret: "6543210987654321"))
        XCTAssertNotEqual(value.encrypted(), value)
    }

    func testSubscripts() {
        let text = "ABCDEF"
        XCTAssertEqual(text[1], "B")
        XCTAssertEqual(text[-1], "F")
        XCTAssertEqual(String(text[1, 3]), "BCD")
    }
}
