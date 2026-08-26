import Foundation
import UIKit
@testable import DojahWidget

final class MockEmailView: EmailViewProtocol {
    var shownEmailError: String?
    var hideEmailErrorCalled = false
    var showVerifyCalled = false
    var prefilledEmail: String?
    var shownError: String?
    var shownSuccess: String?
    var hideMessageCalled = false

    func showEmailError(_ message: String) { shownEmailError = message }
    func hideEmailError() { hideEmailErrorCalled = true }
    func showVerifyController() { showVerifyCalled = true }
    func prefillEmail(email: String) { prefilledEmail = email }
    func showErrorMessage(_ message: String) { shownError = message }
    func showSuccessMessage(_ message: String) { shownSuccess = message }
    func hideMessage() { hideMessageCalled = true }
}

final class MockPhoneNumberView: PhoneNumberViewProtocol {
    var lastPhoneCode: String?
    var continueEnabled: Bool?
    var showVerifyCalled = false
    var lastMethod: String?
    var lastMethodIndex: Int?
    var shownError: String?
    var hideMessageCalled = false

    func updateCountryDetails(phoneCode: String, flag: UIImage) { lastPhoneCode = phoneCode }
    func enableContinueButton(_ enable: Bool) { continueEnabled = enable }
    func showVerifyController() { showVerifyCalled = true }
    func updateVerificationMethod(method: String, index: Int) {
        lastMethod = method
        lastMethodIndex = index
    }
    func showErrorMessage(_ message: String) { shownError = message }
    func hideMessage() { hideMessageCalled = true }
}

final class MockCountryPickerView: CountryPickerViewProtocol {
    var refreshCalled = false
    var continueEnabled: Bool?
    var shownError: String?
    var hideMessageCalled = false

    func refreshCountries() { refreshCalled = true }
    func enableContinueButton(_ enable: Bool) { continueEnabled = enable }
    func showErrorMessage(_ message: String) { shownError = message }
    func hideMessage() { hideMessageCalled = true }
}

final class MockDisclaimerView: DJDisclaimerViewProtocol {
    var continueEnabled: Bool?
    var shownError: String?

    func enableContinueButton(_ enable: Bool) { continueEnabled = enable }
    func showErrorMessage(_ message: String) { shownError = message }
}

final class MockBusinessDataView: BusinessDataViewProtocol {
    var updateNumberFieldCalled = false
    var companyTypeHidden: Bool?
    var businessNameHidden: Bool?
    var shownError: String?
    var hideMessageCalled = false

    func updateNumberTextfield() { updateNumberFieldCalled = true }
    func showOrHideBusinessNameView(isHidden: Bool) { businessNameHidden = isHidden }
    func showOrhideCompanyTypeView(isHidden: Bool) { companyTypeHidden = isHidden }
    func showErrorMessage(_ message: String) { shownError = message }
    func hideMessage() { hideMessageCalled = true }
}

final class MockUserDataView: UserDataViewProtocol {
    var shownError: String?
    var hideMessageCalled = false

    func showErrorMessage(_ message: String) { shownError = message }
    func hideMessage() { hideMessageCalled = true }
}

final class MockOTPView: VerifyOTPViewProtocol {
    var startTimerCalled = false
    var shownError: String?
    var hideMessageCalled = false

    func startCountdownTimer() { startTimerCalled = true }
    func showErrorMessage(_ message: String) { shownError = message }
    func hideMessage() { hideMessageCalled = true }
}

final class MockGovernmentDataView: GovernmentDataViewProtocol {
    var showNumberFieldCalled = false
    var updateMethodsCalled = false
    var shownError: String?
    var hideMessageCalled = false
    var errorActionCalled = false

    func showGovtIDNumberTextField() { showNumberFieldCalled = true }
    func errorAction() { errorActionCalled = true }
    func updateVerificationMethods() { updateMethodsCalled = true }
    func showErrorMessage(_ message: String) { shownError = message }
    func hideMessage() { hideMessageCalled = true }
}

final class MockSDKInitView: SDKInitViewProtocol {
    var loaderShown: Bool?
    var failedShown = false
    var disclaimerShown = false
    var countryNotSupportedShown = false
    var verificationSuccessfulShown = false
    var onFailed: (() -> Void)?
    var onDisclaimer: (() -> Void)?
    var onCountryNotSupported: (() -> Void)?
    var onVerificationSuccessful: (() -> Void)?

    func showLoader(_ show: Bool) { loaderShown = show }
    func showSDKInitFailedView() {
        failedShown = true
        onFailed?()
    }
    func showDisclaimer() {
        disclaimerShown = true
        onDisclaimer?()
    }
    func showCountryNotSupportedError() {
        countryNotSupportedShown = true
        onCountryNotSupported?()
    }
    func showVerificationSuccessful() {
        verificationSuccessfulShown = true
        onVerificationSuccessful?()
    }
}

final class MockAddressView: AddressVerificationViewProtocol {
    var showPlacesCalled = false
    var showProvincesCalled = false
    var continueEnabled: Bool?
    var captureUtilityBillCalled = false
    var shownError: String?
    var hideMessageCalled = false

    func showPlacesResults() { showPlacesCalled = true }
    func showProvincesResults() { showProvincesCalled = true }
    func enableContinueButton(_ enable: Bool) { continueEnabled = enable }
    func captureUtilityBill() { captureUtilityBillCalled = true }
    func showErrorMessage(_ message: String) { shownError = message }
    func hideMessage() { hideMessageCalled = true }
}

final class MockGovtIDCaptureView: GovtIDCaptureViewProtocol {
    var imageError: String?
    var updateUICalled = false
    var shownError: String?

    func showIDImageError(message: String) { imageError = message }
    func updateUI() { updateUICalled = true }
    func showErrorMessage(_ message: String) { shownError = message }
}

final class MockUtilityBillView: UtilityBillViewProtocol {
    var imageError: String?
    var updateUICalled = false
    var shownError: String?

    func showIDImageError(message: String) { imageError = message }
    func updateUI() { updateUICalled = true }
    func showErrorMessage(_ message: String) { shownError = message }
}

final class MockSelfieView: SelfieVideoKYCViewProtocol {
    var selfieError: String?
    var shownError: String?

    func showSelfieImageError(message: String) { selfieError = message }
    func showErrorMessage(_ message: String) { shownError = message }
}

final class MockCustomQuestionsView: CustomQuestionsViewProtocol {
    var submitEnabled: Bool?
    var lastResult: CustomQuestionsResult?

    func enableSubmitButton(_ enabled: Bool) { submitEnabled = enabled }
    func deliverResult(_ result: CustomQuestionsResult) { lastResult = result }
}
