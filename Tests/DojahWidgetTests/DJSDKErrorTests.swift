import XCTest
@testable import DojahWidget

final class DJSDKErrorTests: XCTestCase {
    func testGenericUiMessage() {
        let generic = "An error occured. Try again later"
        [
            DJSDKError.invalidURL,
            .resourceNotFound,
            .serverFailure,
            .tryAgain,
            .lowBalance,
            .noResponseData,
            .requestFailure(reason: "x"),
            .decodingFailure(reason: "x"),
            .encodingFailure(reason: "x"),
            .networkError("ignored")
        ].forEach {
            XCTAssertEqual($0.uiMessage, generic)
        }
    }

    func testSpecificUiMessages() {
        XCTAssertEqual(DJSDKError.unableToLoadLocalJSON.uiMessage, "Unable to load local JSON file.")
        XCTAssertEqual(DJSDKError.invalidOTPEntered.uiMessage, "Invalid OTP entered. Please, input the correct OTP")
        XCTAssertEqual(DJSDKError.OTPCouldNotBeSent.uiMessage, "OTP Could not be sent, Please try again")
        XCTAssertEqual(DJSDKError.invalidIDNotFoundThirdParty.uiMessage, "invalidIDNotFound")
        XCTAssertEqual(
            DJSDKError.invalidIDNotFoundThirdPartyMessage(.bvn).uiMessage,
            "BVN is currently not available. Please try another means of identification"
        )
        XCTAssertEqual(
            DJSDKError.invalidIDNotFoundGovernmentData(.nin).uiMessage,
            "Invalid NIN. Input a valid NIN or try another means of Identification"
        )
        XCTAssertEqual(
            DJSDKError.invalidIDNotFoundBusinessData(.cac).uiMessage,
            "Invalid RC-NUMBER. Input a valid RC-NUMBER or try another means of Identification"
        )
        XCTAssertEqual(DJSDKError.selfieVideoCouldNotBeCaptured.uiMessage, "Please move to a well lit environment and try again")
        XCTAssertEqual(DJSDKError.govtIDCouldNotBeCaptured.uiMessage, "Document is not clear enough, please try again")
        XCTAssertEqual(DJSDKError.imageCheckOrAnalysisError.uiMessage, "imageCheckOrAnalysisError")
        XCTAssertEqual(DJSDKError.invalidIDThirdPartyFailure.uiMessage, "invalidIDThirdPartyFailure")
        XCTAssertEqual(DJSDKError.countryNotSupported.uiMessage, "Widget is not supported in your country")
        XCTAssertEqual(DJSDKError.verificationCompleted.uiMessage, "verificationCompleted")
    }

    func testEquatable() {
        XCTAssertEqual(DJSDKError.tryAgain, .tryAgain)
        XCTAssertEqual(DJSDKError.networkError("a"), .networkError("a"))
        XCTAssertNotEqual(DJSDKError.networkError("a"), .networkError("b"))
        XCTAssertNotEqual(DJSDKError.invalidURL, .serverFailure)
    }
}
