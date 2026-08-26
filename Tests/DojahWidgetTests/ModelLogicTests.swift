import XCTest
@testable import DojahWidget

final class ModelLogicTests: XCTestCase {
    func testDJGovernmentIDTypeRemotePathAndLookupKey() {
        XCTAssertEqual(DJGovernmentIDType.bvn.remotePath.path, DJRemotePath.bvnLookup.path)
        XCTAssertEqual(DJGovernmentIDType.bvnAdvance.remotePath.path, DJRemotePath.bvnAdvanceLookup.path)
        XCTAssertEqual(DJGovernmentIDType.nin.remotePath.path, DJRemotePath.ninLookup.path)
        XCTAssertEqual(DJGovernmentIDType.vnin.remotePath.path, DJRemotePath.vninLookup.path)
        XCTAssertEqual(DJGovernmentIDType.mobile.remotePath.path, DJRemotePath.basicPhoneNumberLookup.path)
        XCTAssertEqual(DJGovernmentIDType.dl.remotePath.path, DJRemotePath.none.path)

        XCTAssertEqual(DJGovernmentIDType.bvn.lookupParameterKeyName, "bvn")
        XCTAssertEqual(DJGovernmentIDType.bvnAdvance.lookupParameterKeyName, "bvn")
        XCTAssertEqual(DJGovernmentIDType.nin.lookupParameterKeyName, "nin")
        XCTAssertEqual(DJGovernmentIDType.vnin.lookupParameterKeyName, "vnin")
        XCTAssertEqual(DJGovernmentIDType.mobile.lookupParameterKeyName, "phone_number")
        XCTAssertEqual(DJGovernmentIDType.passportID.lookupParameterKeyName, "")
    }

    func testDJGovernmentIDTypeFlags() {
        XCTAssertTrue(DJGovernmentIDType.dl.isFrontAndBack)
        XCTAssertTrue(DJGovernmentIDType.nationalID.isFrontAndBack)
        XCTAssertTrue(DJGovernmentIDType.ngVotersCard.isFrontAndBack)
        XCTAssertFalse(DJGovernmentIDType.bvn.isFrontAndBack)
        XCTAssertTrue(DJGovernmentIDType.nin.isNGNIN)
        XCTAssertTrue(DJGovernmentIDType.vnin.isNGNIN)
        XCTAssertTrue(DJGovernmentIDType.ngNINSlip.isNGNIN)
        XCTAssertFalse(DJGovernmentIDType.bvn.isNGNIN)
    }

    func testDJGovernmentIDComputedProperties() {
        XCTAssertEqual(TestFixtures.governmentID(name: "SMS OTP").verificationModeParam, "OTP")
        XCTAssertEqual(TestFixtures.governmentID(name: "Selfie Check").verificationModeParam, "LIVENESS")
        XCTAssertEqual(TestFixtures.governmentID(name: "WhatsApp OTP").verificationModeParam, "Whatsapp")
        XCTAssertNil(TestFixtures.governmentID(name: "BVN").verificationModeParam)
        XCTAssertNil(TestFixtures.governmentID(name: nil).verificationModeParam)

        XCTAssertEqual(TestFixtures.governmentID(name: "Y", idEnum: "BVN", value: "X").idTypeParam, "BVN")
        XCTAssertEqual(TestFixtures.governmentID(idEnum: nil, value: "NIN").idTypeParam, "NIN")
        XCTAssertEqual(TestFixtures.governmentID(name: "DL", idEnum: nil, value: nil).idTypeParam, "DL")
        XCTAssertEqual(DJGovernmentID.empty.idTypeParam, "")

        XCTAssertEqual(TestFixtures.governmentID(value: "BVN").idType, .bvn)
        XCTAssertNil(TestFixtures.governmentID(value: "unknown").idType)

        XCTAssertEqual(TestFixtures.governmentID(name: "otp").verificationMethod, .phoneNumberOTP)
        XCTAssertEqual(TestFixtures.governmentID(name: "selfie").verificationMethod, .selfie)
        XCTAssertEqual(TestFixtures.governmentID(name: "selfie-video").verificationMethod, .selfieVideo)
        XCTAssertEqual(TestFixtures.governmentID(name: "whatsappotp").verificationMethod, .whatsappOtp)
        XCTAssertNil(TestFixtures.governmentID(name: "bvn").verificationMethod)

        let ids = [
            TestFixtures.governmentID(name: "BVN", idEnum: "BVN"),
            TestFixtures.governmentID(name: "NIN", idEnum: "NIN")
        ]
        XCTAssertEqual(ids.names, ["BVN", "NIN"])
        XCTAssertEqual(ids.symbols, ["bvn", "nin"])
    }

    func testBusinessDataTypeAndAddressType() {
        XCTAssertEqual(BusinessDataType.cac.remotePath.path, DJRemotePath.cac.path)
        XCTAssertEqual(BusinessDataType.tin.remotePath.path, DJRemotePath.tin.path)
        XCTAssertEqual(BusinessDataType.cac.verificationRequestParam, "rc_number")
        XCTAssertEqual(BusinessDataType.tin.verificationRequestParam, "tin")
        XCTAssertEqual(AddressType.userSelected.remotePath.path, DJRemotePath.baseAddress.path)
        XCTAssertEqual(AddressType.userLocation.remotePath.path, DJRemotePath.address.path)
    }

    func testDJInputModeKeyboardType() {
        XCTAssertEqual(DJInputMode.numeric.keyboardType, .numberPad)
        XCTAssertEqual(DJInputMode.number.keyboardType, .numberPad)
        XCTAssertEqual(DJInputMode.text.keyboardType, .alphabet)
    }

    func testDJEventRequestHelpers() {
        let completed = DJEventRequest.event(name: .stepCompleted, pageName: .email, services: ["svc"])
        XCTAssertEqual(completed.name, .stepCompleted)
        XCTAssertEqual(completed.value, "email")
        XCTAssertEqual(completed.services, ["svc"])
        XCTAssertTrue(completed.hasServices)
        XCTAssertTrue(DJEventRequest(name: .stepFailed, value: "x").hasServices)
        XCTAssertFalse(DJEventRequest(name: .emailCollected, value: "x").hasServices)

        let failed = DJEventRequest.stepFailed(errorCode: .invalidOTP, services: ["a"])
        XCTAssertEqual(failed.name, .stepFailed)
        XCTAssertEqual(failed.value, "04")
        XCTAssertEqual(failed.services, ["a"])
    }

    func testDecisionStatusFeedback() {
        XCTAssertEqual(DecisionStatus.approved.feedbackType, .success)
        XCTAssertEqual(DecisionStatus.pending.feedbackType, .warning)
        XCTAssertEqual(DecisionStatus.failed.feedbackType, .failure)
        XCTAssertEqual(DecisionStatus.approved.verificationStatus, "approved")
        XCTAssertEqual(DecisionStatus.pending.verificationStatus, "pending")
        XCTAssertEqual(DecisionStatus.failed.verificationStatus, "failed")
        XCTAssertTrue(DecisionStatus.approved.feedbackMessage.contains("successfully"))
        XCTAssertEqual(DecisionStatus.approved.feedbackTitle, "Verification successful")
        XCTAssertEqual(DecisionResponse(status: nil, reason: "x").feedbackType, .warning)
        XCTAssertEqual(DecisionResponse(status: .approved, reason: nil).feedbackType, .success)
    }

    func testAuthStepEqualityAndFilters() {
        let a = TestFixtures.authStep(name: .email, id: 1, status: .pending)
        let b = TestFixtures.authStep(name: .email, id: 1, status: .done)
        let c = TestFixtures.authStep(name: .phoneNumber, id: 1, status: .pending)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertEqual(DJAuthStep.index.name, .index)
        let steps = [
            TestFixtures.authStep(id: 1, status: .done),
            TestFixtures.authStep(name: .email, id: 2, status: .pending),
            TestFixtures.authStep(name: .userData, id: 3, status: .notdone)
        ]
        XCTAssertEqual(steps.by(statuses: [.pending, .notdone]).map(\.id), [2, 3])
    }

    func testPagesByName() {
        let pages = [
            TestFixtures.page(name: .email),
            TestFixtures.page(name: .userData)
        ]
        XCTAssertEqual(pages.by(pageName: .email)?.pageName, .email)
        XCTAssertNil(pages.by(pageName: .selfie))
    }

    func testStringOrIntEnumAndContinent() throws {
        XCTAssertEqual(StringOrIntEnum.integer(12).value, "12")
        XCTAssertEqual(StringOrIntEnum.string("NG").value, "NG")

        let encodedInt = try JSONEncoder().encode(StringOrIntEnum.integer(7))
        XCTAssertEqual(String(data: encodedInt, encoding: .utf8), "7")
        let encodedString = try JSONEncoder().encode(StringOrIntEnum.string("NG"))
        XCTAssertEqual(String(data: encodedString, encoding: .utf8), "\"NG\"")

        XCTAssertEqual(try JSONDecoder().decode(StringOrIntEnum.self, from: Data("42".utf8)).value, "42")
        XCTAssertEqual(try JSONDecoder().decode(StringOrIntEnum.self, from: Data("\"KE\"".utf8)).value, "KE")
        XCTAssertThrowsError(try JSONDecoder().decode(StringOrIntEnum.self, from: Data("true".utf8)))
        XCTAssertEqual(Continent.africa.rawValue, "Africa")
    }

    func testDJCountryMapsToCountryDB() throws {
        let json = """
        {
          "Country Name": "Nigeria",
          "ISO2": "NG",
          "ISO3": "NGA",
          "Top Level Domain": ".ng",
          "FIPS": "NI",
          "ISO Numeric": 566,
          "GeoNameID": "2328926",
          "E164": 234,
          "Phone Code": 234,
          "Continent": "Africa",
          "Capital": "Abuja",
          "Time Zone in Capital": "Africa/Lagos",
          "Currency": "NGN",
          "Language Codes": "en",
          "Languages": "English",
          "Area KM2": 923768,
          "Internet Hosts": "1",
          "Internet Users": 2,
          "Phones (Mobile)": "3",
          "Phones (Landline)": 4,
          "GDP": "5"
        }
        """
        let country: DJCountry = TestFixtures.decode(json)
        XCTAssertEqual(country.countryDB.iso2, "NG")
        XCTAssertEqual(country.countryDB.phoneCode, "234")
        XCTAssertEqual(country.countryDB.isoNumeric, "566")
        XCTAssertEqual(country.countryDB.internetUsers, "2")
    }

    func testLookupEntityHelpers() {
        let entity = TestFixtures.lookupEntity()
        XCTAssertEqual(entity.phoneNumber, "08012345678")
        XCTAssertEqual(
            entity.dataCollectedParam(idEnum: "BVN", countryCode: "NG"),
            "cust-1|BVN|NG|Ada|King|Lovelace|10-12-1815"
        )

        let fallback = TestFixtures.lookupEntity(
            firstName: nil,
            lastName: nil,
            middleName: nil,
            phoneNumber1: nil,
            phoneNumber2: "0700",
            firstname: "Funmi",
            middlename: nil,
            phoneNumberMiddleName: "Mid"
        )
        XCTAssertEqual(fallback.phoneNumber, "0700")
        XCTAssertTrue(fallback.dataCollectedParam(idEnum: "NIN", countryCode: "NG").contains("Funmi"))
        XCTAssertTrue(fallback.dataCollectedParam(idEnum: "NIN", countryCode: "NG").contains("Mid"))
    }

    func testCompanyType() {
        XCTAssertEqual(CompanyType.businessName.serverKey, "BUSINESS_NAME")
        XCTAssertEqual(CompanyType.incorporatedTrustees.title, "Incorporated Trustees")
        XCTAssertEqual(CompanyType.titles.count, CompanyType.allCases.count)
        XCTAssertTrue(CompanyType.titles.contains("Limited Partnership"))
    }

    func testDJRequestHeadersCodingKeys() throws {
        let headers = DJRequestHeaders(appID: "app", publicKey: "pk", sessionID: "s", referenceID: "r")
        let dict = headers.dictionary
        XCTAssertEqual(dict["app-id"] as? String, "app")
        XCTAssertEqual(dict["p-key"] as? String, "pk")
        XCTAssertEqual(dict["session"] as? String, "s")
        XCTAssertEqual(dict["reference"] as? String, "r")
    }

    func testImageVerificationValueDecodesFlexibleConfidence() throws {
        let asDouble: ImageVerificationValue = TestFixtures.decode(#"{"url":"u","confidence_value":1.5}"#)
        XCTAssertEqual(asDouble.confidenceValue, "1.5")
        let asInt: ImageVerificationValue = TestFixtures.decode(#"{"url":"u","confidence_value":2}"#)
        XCTAssertEqual(asInt.confidenceValue, "2.0")
        let asString: ImageVerificationValue = TestFixtures.decode(#"{"url":"u","confidence_value":"high"}"#)
        XCTAssertEqual(asString.confidenceValue, "high")
        let missing: ImageVerificationValue = TestFixtures.decode(#"{"url":"u"}"#)
        XCTAssertNil(missing.confidenceValue)
    }

    func testDJIPAddressEntityDecodesAsFieldAsIntOrString() {
        let asInt: DJIPAddressEntity = TestFixtures.decode(#"{"as":12345,"country":"Nigeria"}"#)
        XCTAssertEqual(asInt.entityAs, "12345")
        XCTAssertEqual(asInt.country, "Nigeria")
        let asString: DJIPAddressEntity = TestFixtures.decode(#"{"as":"AS123","country":"Kenya"}"#)
        XCTAssertEqual(asString.entityAs, "AS123")
    }
}
