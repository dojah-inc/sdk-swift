import XCTest
@testable import DojahWidget

final class ViewStateAndUIModelTests: XCTestCase {
    func testGovtIDCaptureViewStateCopy() {
        XCTAssertEqual(GovtIDCaptureViewState.uploadFront.title, "Upload the front of your ID")
        XCTAssertEqual(GovtIDCaptureViewState.captureBack.title, "Capture the back of your ID")
        XCTAssertEqual(GovtIDCaptureViewState.previewCACDocument.title, "Preview CAC Document")
        XCTAssertEqual(GovtIDCaptureViewState.uploadFront.primaryButtonTitle, "Upload")
        XCTAssertEqual(GovtIDCaptureViewState.captureFront.primaryButtonTitle, "Capture")
        XCTAssertEqual(GovtIDCaptureViewState.previewFront.primaryButtonTitle, "Continue")
        XCTAssertEqual(GovtIDCaptureViewState.uploadFront.secondaryButtonTitle, "Capture Instead")
        XCTAssertEqual(GovtIDCaptureViewState.captureFront.secondaryButtonTitle, "Upload Instead")
        XCTAssertEqual(GovtIDCaptureViewState.previewFront.secondaryButtonTitle, "Retake")
    }

    func testUtilityBillCaptureStateCopy() {
        XCTAssertEqual(UtilityBillCaptureState.upload.title, "Upload Utility Bill")
        XCTAssertEqual(UtilityBillCaptureState.capture.title, "Capture Utility Bill")
        XCTAssertEqual(UtilityBillCaptureState.preview.title, "Preview")
        XCTAssertEqual(UtilityBillCaptureState.upload.primaryButtonTitle, "Upload")
        XCTAssertEqual(UtilityBillCaptureState.capture.primaryButtonTitle, "Capture")
        XCTAssertEqual(UtilityBillCaptureState.preview.primaryButtonTitle, "Continue")
        XCTAssertEqual(UtilityBillCaptureState.upload.secondaryButtonTitle, "Capture Instead")
        XCTAssertEqual(UtilityBillCaptureState.capture.secondaryButtonTitle, "Upload Instead")
        XCTAssertEqual(UtilityBillCaptureState.preview.secondaryButtonTitle, "Retake")
    }

    func testSelfieVideoKYCViewStateCopy() {
        XCTAssertEqual(SelfieVideoKYCViewState.capture.primaryButtonTitle, "Capture")
        XCTAssertEqual(SelfieVideoKYCViewState.record.primaryButtonTitle, "Record")
        XCTAssertEqual(SelfieVideoKYCViewState.previewSelfie.primaryButtonTitle, "Continue")
        XCTAssertEqual(SelfieVideoKYCViewState.previewSelfieVideo.primaryButtonTitle, "Continue")
        XCTAssertTrue(SelfieVideoKYCViewState.capture.hintText.contains("Capture"))
        XCTAssertTrue(SelfieVideoKYCViewState.record.hintText.contains("Record"))
        XCTAssertEqual(SelfieVideoKYCViewState.previewSelfie.hintText, "Preview your selfie")
        XCTAssertEqual(SelfieVideoKYCViewState.previewSelfieVideo.hintText, "Preview your selfie video")
    }

    func testGovtIDVerificationMethod() {
        XCTAssertEqual(GovtIDVerificationMethod.selfie.title, "Selfie")
        XCTAssertEqual(GovtIDVerificationMethod.whatsappOtp.title, "WhatsApp")
        XCTAssertEqual(GovtIDVerificationMethod.phoneNumberOTP.title, "Phone Number OTP")
        XCTAssertEqual(GovtIDVerificationMethod.emailOTP.title, "Email OTP")
        XCTAssertEqual(GovtIDVerificationMethod.selfieVideo.title, "Video KYC")
        XCTAssertEqual(GovtIDVerificationMethod.govtID.title, "Govt. ID")
        XCTAssertEqual(GovtIDVerificationMethod.selfie.kycText, "Capture")
        XCTAssertEqual(GovtIDVerificationMethod.selfieVideo.kycText, "Record")
        XCTAssertEqual(GovtIDVerificationMethod.whatsappOtp.kycText, "WhatsApp")
        XCTAssertEqual(GovtIDVerificationMethod.phoneNumberOTP.kycText, "")
        XCTAssertEqual(GovtIDVerificationMethod.allCases.titles.count, GovtIDVerificationMethod.allCases.count)
    }

    func testPermissionTypeDisclaimerItems() {
        XCTAssertEqual(PermissionType.camera.disclaimerItems, DJConstants.idCaptureDisclaimerItems)
        XCTAssertEqual(PermissionType.location.disclaimerItems, DJConstants.locationDisclaimerItems)
        XCTAssertEqual(PermissionType.camera.rawValue, "Camera")
        XCTAssertEqual(PermissionType.location.rawValue, "Location")
        XCTAssertNotNil(PermissionType.camera.icon)
        XCTAssertNotNil(PermissionType.location.icon)
    }

    func testFeedbackTypeAndConfig() {
        XCTAssertEqual(FeedbackType.success.lottieAnimationName, "check_1")
        XCTAssertEqual(FeedbackType.failure.lottieAnimationName, "error")
        XCTAssertEqual(FeedbackType.countryNotSupported.lottieAnimationName, "error")
        XCTAssertEqual(FeedbackType.warning.lottieAnimationName, "check_1")

        let error = FeedbackConfig.error(message: "boom")
        XCTAssertEqual(error.feedbackType, .failure)
        XCTAssertEqual(error.message, "boom")
        XCTAssertTrue(error.showNavControls)

        let success = FeedbackConfig.success(titleText: "Done", message: "ok", showNavControls: false)
        XCTAssertEqual(success.feedbackType, .success)
        XCTAssertEqual(success.titleText, "Done")
        XCTAssertFalse(success.showNavControls)
    }

    func testDJMonthNames() {
        XCTAssertEqual(DJMonth.allCases.count, 12)
        XCTAssertEqual(DJMonth.jan.rawValue, 1)
        XCTAssertEqual(DJMonth.dec.rawValue, 12)
        XCTAssertEqual(DJMonth.jan.name, "January")
        XCTAssertEqual(DJMonth.dec.name, "December")
        XCTAssertEqual(DJMonth.allCases.names.first, "January")
        XCTAssertEqual(DJMonth.allCases.names.last, "December")
    }

    func testIconConfigDefaultsAndIconPosition() {
        let config = IconConfig()
        XCTAssertNil(config.icon)
        XCTAssertEqual(config.size, .zero)
        XCTAssertEqual(config.contentMode, .scaleAspectFit)
        XCTAssertEqual(IconPosition.left, .left)
        XCTAssertEqual(IconPosition.right, .right)
    }

    func testAttributedStringBuilder() {
        let builder = AttributedStringBuilder()
        builder.defaultAttributes = [.textColor(.red)]
        builder.text("Hello", attributes: [.font(.systemFont(ofSize: 12))])
            .space()
            .text("World")
            .newline()
            .tab()
            .spaces(2)
            .newlines(2)
            .tabs(1)
        XCTAssertTrue(builder.attributedString.string.contains("Hello World"))
        XCTAssertTrue(builder.attributedString.string.contains("\n"))
        XCTAssertTrue(builder.attributedString.string.contains("\t"))

        builder.clearDefaultAttributes()
        XCTAssertTrue(builder.defaultAttributes.isEmpty)

        let extra = NSAttributedString(string: "Extra")
        builder.attributedText(extra)
        XCTAssertTrue(builder.attributedString.string.contains("Extra"))

        let image = UIImage.imageWithColor(color: .blue, size: CGSize(width: 10, height: 20))!
        builder.image(image)
        builder.image(image, width: 5)
        builder.image(image, height: 8)
        builder.image(image, size: CGSize(width: 4, height: 4))
        builder.image(image, withSizeFittingFontUppercase: .systemFont(ofSize: 14))
        builder.image(image, withSizeFittingFontLowercase: .systemFont(ofSize: 14))
        XCTAssertGreaterThan(builder.attributedString.length, 0)

        XCTAssertEqual(AttributedStringBuilder.Attribute.font(.systemFont(ofSize: 10)).key, .font)
        XCTAssertNotNil(AttributedStringBuilder.Attribute.textColor(.black).value)
        XCTAssertEqual(AttributedStringBuilder.Attribute.alignment(.center).key, .paragraphStyle)
        XCTAssertNil(AttributedStringBuilder.Attribute.lineSpacing(2).value)
    }

    func testCountryEmoticonHelpers() {
        let nigeria = TestFixtures.country(iso2: "NG")
        XCTAssertFalse(nigeria.emoticon.isEmpty)
        XCTAssertTrue(nigeria.emoticonCountryName.contains("Nigeria"))
        XCTAssertTrue([nigeria].emoticonPhoneCodes.first?.contains("234") ?? false)
        XCTAssertNotNil(nigeria.flag)
    }

    func testPreferenceKeysExist() {
        XCTAssertEqual(PreferenceKey.DJWidgetID.rawValue, "DJWidgetID")
        XCTAssertEqual(PreferenceKey.DJCurrentPageID.rawValue, "DJCurrentPageID")
        XCTAssertEqual(PreferenceKey.PlatformSource.rawValue, "PlatformSource")
    }
}
