import XCTest
@testable import DojahWidget

final class InputValidatorTests: XCTestCase {
    private var sut: InputValidatorImpl!

    override func setUp() {
        super.setUp()
        sut = InputValidatorImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Email

    func testValidateEmailAddress_empty_returnsCannotBeEmpty() {
        let result = sut.validateEmailAddress("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Cannot be empty")
        XCTAssertEqual(result.validationType, .email)
    }

    func testValidateEmailAddress_invalidFormats() {
        ["plain", "a@", "@b.com", "a@b", "a@b.c", "spaces emma@x.com"].forEach { email in
            let result = sut.validateEmailAddress(email)
            XCTAssertFalse(result.isValid, "Expected invalid for \(email)")
            XCTAssertEqual(result.message, "Invalid email address")
        }
    }

    func testValidateEmailAddress_validAndTrimmed() {
        ["user@example.com", "  user@example.com  ", "USER@Example.COM"].forEach { email in
            let result = sut.validateEmailAddress(email)
            XCTAssertTrue(result.isValid, "Expected valid for \(email)")
            XCTAssertEqual(result.message, "")
        }
    }

    func testValidateEmailAddress_subdomainAndPlusTag() {
        XCTAssertTrue(sut.validateEmailAddress("dev+tag@mail.dojah.io").isValid)
    }

    // MARK: - Email or phone

    func testValidateEmailOrPhone_empty() {
        let result = sut.validateEmailOrPhone("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Cannot be empty")
        XCTAssertEqual(result.validationType, .emailOrPhone)
    }

    func testValidateEmailOrPhone_acceptsEmailOrElevenCharPhone() {
        XCTAssertTrue(sut.validateEmailOrPhone("user@example.com").isValid)
        XCTAssertTrue(sut.validateEmailOrPhone("08012345678").isValid)
        XCTAssertTrue(sut.validateEmailOrPhone("+2348012345").isValid)
    }

    func testValidateEmailOrPhone_rejectsShortPhoneAndMalformedEmail() {
        XCTAssertFalse(sut.validateEmailOrPhone("0801234567").isValid)
        XCTAssertFalse(sut.validateEmailOrPhone("not-an-email").isValid)
        XCTAssertEqual(sut.validateEmailOrPhone("abc").message, "Invalid email or phone")
    }

    // MARK: - Phone

    func testValidatePhoneNumber_emptyAndInvalid() {
        XCTAssertEqual(sut.validatePhoneNumber("").message, "Cannot be empty")
        XCTAssertEqual(sut.validatePhoneNumber("080123456").message, "Invalid phone number")
        XCTAssertEqual(sut.validatePhoneNumber("abcdefghij").message, "Invalid phone number")
    }

    func testValidatePhoneNumber_requiresExactlyTenDigitsOrPlus() {
        XCTAssertTrue(sut.validatePhoneNumber("0801234567").isValid)
        XCTAssertTrue(sut.validatePhoneNumber("+234567890").isValid)
        XCTAssertFalse(sut.validatePhoneNumber("08012345678").isValid)
    }

    // MARK: - Name

    func testValidateName_emptyInvalidAndLettersOnly() {
        XCTAssertEqual(sut.validateName("").message, "Cannot be empty")
        XCTAssertEqual(sut.validateName("A").message, "Must be at least 2 characters(letters only)")
        XCTAssertEqual(sut.validateName("A1").message, "Must be at least 2 characters(letters only)")
        XCTAssertTrue(sut.validateName("Jo").isValid)
        XCTAssertTrue(sut.validateName("John Doe").isValid)
        XCTAssertTrue(sut.validateName("  Ada  ").isValid)
    }

    // MARK: - Address

    func testValidateAddress_emptyAndShort() {
        XCTAssertEqual(sut.validateAddress("").message, "Cannot be empty")
        XCTAssertEqual(sut.validateAddress("").validationType, .name)
        XCTAssertFalse(sut.validateAddress("#").isValid)
        XCTAssertTrue(sut.validateAddress("12, Broad Street").isValid)
        XCTAssertTrue(sut.validateAddress("Ab").isValid)
    }

    // MARK: - Password

    func testValidatePassword_emptyShortAndValid() {
        XCTAssertEqual(sut.validatePassword("").message, "Cannot be empty")
        XCTAssertEqual(sut.validatePassword("12345").message, "Minimum 8 characters")
        XCTAssertTrue(sut.validatePassword("123456").isValid, "Implementation treats 6+ characters as valid")
        XCTAssertTrue(sut.validatePassword("password").isValid)
    }

    func testValidateConfirmPassword_emptyShortMismatchAndMatch() {
        XCTAssertEqual(sut.validateConfirmPassword("secret", "").message, "Cannot be empty")
        XCTAssertEqual(sut.validateConfirmPassword("secret", "12345").message, "Minimum 8 characters")
        XCTAssertEqual(sut.validateConfirmPassword("abcdef", "abcdefg").message, "Password mismatch")
        XCTAssertTrue(sut.validateConfirmPassword("abcdef", "abcdef").isValid)
    }

    // MARK: - Amount

    func testValidateAmount_emptyZeroAndValid() {
        XCTAssertEqual(sut.validateAmount("").message, "Cannot be empty")
        XCTAssertEqual(sut.validateAmount("0").message, "Invalid amount")
        XCTAssertEqual(sut.validateAmount("0.0").message, "Invalid amount")
        let valid = sut.validateAmount("1,000")
        XCTAssertTrue(valid.isValid)
        XCTAssertEqual(valid.validationType, .password, "Success path currently stamps .password")
    }

    // MARK: - Numeric

    func testValidateNumeric_emptyNonDigitsAndValid() {
        XCTAssertEqual(sut.validateNumeric("").message, "Cannot be empty")
        XCTAssertEqual(sut.validateNumeric("12a").message, "Invalid value")
        XCTAssertEqual(sut.validateNumeric("12.3").message, "Invalid value")
        XCTAssertTrue(sut.validateNumeric("0123").isValid)
    }

    // MARK: - DOB

    func testValidateDOB_emptyInvalidAndValid() {
        XCTAssertEqual(sut.validateDOB("").message, "Cannot be empty")
        XCTAssertEqual(sut.validateDOB("2020-01-01").message, "Invalid date of birth")
        XCTAssertEqual(sut.validateDOB("32-13-2020").message, "Invalid date of birth")
        XCTAssertTrue(sut.validateDOB("01-12-1990").isValid)
    }

    // MARK: - Alphanumeric

    func testValidateAlphaNumeric_emptyIsInvalidOtherwiseAlwaysValid() {
        XCTAssertEqual(sut.validateAlphaNumeric("").message, "Cannot be empty")
        XCTAssertTrue(sut.validateAlphaNumeric("anything!!!").isValid)
    }

    // MARK: - Dispatch by type

    func testValidate_dispatchesToMatchingValidator() {
        XCTAssertTrue(sut.validate("user@example.com", for: .email).isValid)
        XCTAssertTrue(sut.validate("08012345678", for: .emailOrPhone).isValid)
        XCTAssertTrue(sut.validate("0801234567", for: .phoneNumber).isValid)
        XCTAssertTrue(sut.validate("Ada", for: .name).isValid)
        XCTAssertTrue(sut.validate("12 Broad", for: .address).isValid)
        XCTAssertTrue(sut.validate("123456", for: .password).isValid)
        XCTAssertTrue(sut.validate("100", for: .amount).isValid)
        XCTAssertTrue(sut.validate("99", for: .numeric).isValid)
        XCTAssertTrue(sut.validate("01-01-2000", for: .dob).isValid)
        XCTAssertTrue(sut.validate("abc123", for: .alphaNumeric).isValid)
    }

    func testValidate_confirmPasswordTypeUsesPasswordValidatorNotMismatchCheck() {
        let result = sut.validate("123456", for: .confirmPassword)
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.validationType, .password)
    }
}
