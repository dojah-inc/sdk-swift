import XCTest
@testable import DojahWidget

final class ModelCodableTests: XCTestCase {
    func testDJPageConfigRoundTripKeepsKebabKeys() throws {
        let config = DJPageConfig(
            bvn: true,
            ghVoter: true,
            keID: false,
            questions: [DJPageQuestion(text: "Q", type: "text", options: ["a"])],
            titleText: "Hello"
        )
        let data = try JSONEncoder().encode(config)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["gh-voter"] as? Bool, true)
        XCTAssertEqual(json?["ke-id"] as? Bool, false)
        XCTAssertEqual(json?["title"] as? String, "Hello")

        let decoded = try JSONDecoder().decode(DJPageConfig.self, from: data)
        XCTAssertEqual(decoded.bvn, true)
        XCTAssertEqual(decoded.titleText, "Hello")
        XCTAssertEqual(decoded.questions?.first?.text, "Q")
    }

    func testDJEventNameAndPageNameRawValues() {
        XCTAssertEqual(DJEventName.stepCompleted.rawValue, "step_completed")
        XCTAssertEqual(DJEventName.emailCollected.rawValue, "email_collected")
        XCTAssertEqual(DJPageName.userData.rawValue, "user-data")
        XCTAssertEqual(DJPageName.customQuestions.rawValue, "custom-questions")
        XCTAssertEqual(DJEventErrorCode.invalidOTP.rawValue, "04")
        XCTAssertEqual(DJEventErrorCode.unknown.rawValue, "01")
        XCTAssertEqual(DJAuthStepStatus.notdone.rawValue, "notdone")
    }

    func testPricingConfigCodingKeys() throws {
        let json = """
        {
          "aml": {},
          "government-data": {"bvn": "bvn-svc", "gh-dl": "x"},
          "government-data-verification": {"whatsapp": "wa"},
          "selfie": {},
          "business-data": {"cac": "cac-svc"},
          "phone-number": {"verification": "v"},
          "address": {},
          "email": {},
          "business-id": {"default": "biz"},
          "id": {"default": "id"},
          "index": {},
          "countries": {},
          "additional-document": {},
          "signature": {}
        }
        """
        let config = try JSONDecoder().decode(PricingServicesConfig.self, from: Data(json.utf8))
        XCTAssertEqual(config.governmentData.bvn, "bvn-svc")
        XCTAssertEqual(config.governmentData.ghDL, "x")
        XCTAssertEqual(config.governmentDataVerification.whatsappOtp, "wa")
        XCTAssertEqual(config.businessData.cac, "cac-svc")
        XCTAssertEqual(config.id.idDefault, "id")
        XCTAssertEqual(config.businessID.idDefault, "biz")
    }

    func testWidgetAndPreAuthCodingKeys() throws {
        let json = """
        {
          "widget": {
            "published": true,
            "country": ["NG","KE"],
            "review_process": "Automatic",
            "duplicate_check": true,
            "direct_feedback": false,
            "pages": [{"page":"email","config":{"verification":true}}]
          },
          "public_key": "pk",
          "app": {"name":"App","color_code":"#000","id":"app-1"}
        }
        """
        let preAuth = try JSONDecoder().decode(DJPreAuthResponse.self, from: Data(json.utf8))
        XCTAssertEqual(preAuth.publicKey, "pk")
        XCTAssertEqual(preAuth.appConfig?.colorCode, "#000")
        XCTAssertEqual(preAuth.widget?.countries, ["NG", "KE"])
        XCTAssertEqual(preAuth.widget?.pages?.first?.pageName, .email)
        XCTAssertEqual(preAuth.widget?.duplicateCheck, true)
    }

    func testImageCheckAndEmailCollectedCodingKeys() throws {
        let check = try JSONDecoder().decode(
            ImageCheckResponse.self,
            from: Data(#"{"match":true,"reason":"ok","continue_verification":true}"#.utf8)
        )
        XCTAssertEqual(check.match, true)
        XCTAssertEqual(check.continueVerification, true)

        let email = try JSONDecoder().decode(
            EmailCollectedEventResponse.self,
            from: Data(#"{"success":true,"continue_verification":true,"duplicate_reference":false}"#.utf8)
        )
        XCTAssertEqual(email.continueVerification, true)
        XCTAssertEqual(email.duplicateReference, false)
    }

    func testBusinessDataAndOTPResponses() throws {
        let business = try JSONDecoder().decode(
            BusinessDataResponse.self,
            from: Data(#"{"company_name":"Dojah","rc_number":"1","type_of_company":"LTD"}"#.utf8)
        )
        XCTAssertEqual(business.companyName, "Dojah")
        XCTAssertEqual(business.rcNumber, "1")

        let otp = try JSONDecoder().decode(
            OTPRequestResponse.self,
            from: Data(#"{"reference_id":"r","status_id":"1"}"#.utf8)
        )
        XCTAssertEqual(otp.referenceID, "r")
    }

    func testDJGovernmentIDConfigKebabKeys() throws {
        let json = """
        {
          "bvn": {"name":"BVN","enum":"BVN","value":"BVN"},
          "selfie-video": {"name":"selfie-video"},
          "gh-voter": {"name":"GH Voter"},
          "NG-NIN-SLIP": {"name":"NIN Slip"}
        }
        """
        let config = try JSONDecoder().decode(DJGovernmentIDConfig.self, from: Data(json.utf8))
        XCTAssertEqual(config.bvn?.idEnum, "BVN")
        XCTAssertEqual(config.selfieVideo?.name, "selfie-video")
        XCTAssertEqual(config.ghVoter?.name, "GH Voter")
        XCTAssertEqual(config.ngNINSlip?.name, "NIN Slip")
    }

    func testWidgetIDCacheAndCompany() throws {
        let cache = WidgetIDCache(companyName: "Dojah", widgetID: "wid")
        let decoded = try JSONDecoder().decode(WidgetIDCache.self, from: JSONEncoder().encode(cache))
        XCTAssertEqual(decoded.widgetID, "wid")

        let company = try JSONDecoder().decode(DJCompany.self, from: Data(#"{"prod_public_key":"pk"}"#.utf8))
        XCTAssertEqual(company.prodPublicKey, "pk")
    }
}
