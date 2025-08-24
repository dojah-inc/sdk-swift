//
//  OTPVerificationViewModel.swift
//
//
//  Created by Isaac Iniongun on 31/10/2023.
//

import Foundation

final class OTPVerificationViewModel: BaseViewModel {
    private let verificationMethod: GovtIDVerificationMethod = .phoneNumberOTP
    weak var viewProtocol: VerifyOTPViewProtocol?
    private let otpRemoteDatasource: OTPRemoteDatasourceProtocol
    var isPhoneNumberVerification: Bool {
        verificationMethod == .phoneNumberOTP
    }
    var verificationInfo: String {
        let suffix = preference.DJAuthStep.name == .email ? 0 : 4
        let lastDigits = String(preference.DJOTPVerificationInfo.suffix(suffix))
        return "XXXXXXX\(lastDigits)"
    }
    var otp = ""
    private var otpReference = ""
    private var otpRequestChannel: Any {
        switch preference.DJAuthStep.name {
        case .phoneNumber: return preference.DJVerificationMethod
        case .email:
            return "email"
        default:
            return "sms"
        }
    }

    init(
        otpRemoteDatasource: OTPRemoteDatasourceProtocol = OTPRemoteDatasource()
    ) {
        self.otpRemoteDatasource = otpRemoteDatasource
        super.init()
    }

    func requestOTP() {
        showLoader?(true)
        hideMessage()

        print(otpRequestChannel)
        let params: DJParameters = [
            preference.DJAuthStep.name == .email ? "email" : "destination":
                preference.DJOTPVerificationInfo,
            "length": 4,
            "channel": otpRequestChannel,
            "sender_id": "kedesa",
            "priority": true,
        ]

        otpRemoteDatasource.requestOTP(params: params) { [weak self] result in
            self?.showLoader?(false)
            switch result {
            case let .success(entityResponse):
                if let response = entityResponse.entity,
                    let otpReference = response.first?.referenceID
                {
                    self?.otpReference = otpReference
                    runAfter(0.15) {
                        self?.viewProtocol?.startCountdownTimer()
                    }
                } else {
                    self?.showErrorMessage(
                        DJSDKError.OTPCouldNotBeSent.uiMessage
                    )
                }
            case .failure:
                self?.showErrorMessage(DJSDKError.OTPCouldNotBeSent.uiMessage)
            }
        }
    }

    func verifyOTP() {
        showLoader?(true)
        hideMessage()
        let params = [
            "code": otp,
            "reference_id": otpReference,
        ]
        otpRemoteDatasource.validateOTP(params: params) { [weak self] result in
            self?.showLoader?(false)
            switch result {
            case let .success(entityResponse):
                if entityResponse.entity?.valid ?? false {
                    self?.didVerifyOTP()
                } else {
                    self?.sendStepFailedEventForInvalidOTP()
                    self?.showErrorMessage(
                        DJSDKError.invalidOTPEntered.uiMessage
                    )
                }
            case let .failure(error):
                self?.sendStepFailedEventForInvalidOTP()
                self?.showErrorMessage(error.uiMessage)
            }
        }
    }

    private func didVerifyOTP() {
        switch preference.DJAuthStep.name {
        case .phoneNumber:
            logPhoneNumberValidationEvent()
        case .email:
            logEmailCollectedEvent()
        default:
            postStepCompletedEvent()
        }
    }

    private func logPhoneNumberValidationEvent() {
        postEvent(
            request: .init(
                name: .phoneNumberValidation,
                value: "\(preference.DJOTPVerificationInfo),Successful"
            ),
            showLoader: true,
            showError: true,
            didSucceed: { [weak self] _ in
                self?.postStepCompletedEvent()
            },
            didFail: { [weak self] _ in
                self?.postStepCompletedEvent()
            }
        )
    }

    private func postStepCompletedEvent() {
        guard let pageName = preference.DJAuthStep.name else { return }
        postEvent(
            request: .event(name: .stepCompleted, pageName: pageName),
            showLoader: false,
            showError: false,
            didSucceed: { [weak self] _ in
                runAfter { [weak self] in
                    self?.setNextAuthStep()
                }
            },
            didFail: { [weak self] _ in
                runAfter { [weak self] in
                    self?.setNextAuthStep()
                }
            }
        )
    }

    private func sendStepFailedEventForInvalidOTP() {
        postEvent(
            request: .stepFailed(errorCode: .invalidOTP),
            showLoader: false,
            showError: false
        )
    }

    private func hideMessage() {
        runOnMainThread { [weak self] in
            self?.viewProtocol?.hideMessage()
        }
    }

    private func showErrorMessage(_ message: String) {
        showLoader?(false)
        runOnMainThread { [weak self] in
            self?.viewProtocol?.showErrorMessage(message)
        }
    }

    private func logEmailCollectedEvent() {
        let eventRequest = DJEventRequest(
            name: .emailCollected,
            value:
                "\(preference.DJOTPVerificationInfo),Successful,\(preference.preAuthResponse?.widget?.duplicateCheck ?? false)"
        )
        showLoader?(true)
        eventsRemoteDatasource.postEmailCollectedEvent(request: eventRequest) {
            [weak self] result in
            self?.showLoader?(false)
            switch result {
            case let .success(eventsResponse):
                self?.didReceiveEmailCollectedResponse(eventsResponse)
            case let .failure(error):
                self?.viewProtocol?.showErrorMessage(error.uiMessage)
            }
        }
    }

    private func didReceiveEmailCollectedResponse(
        _ response: EntityResponse<EmailCollectedEventResponse>
    ) {
        postEvent(
            request: .event(name: .stepCompleted, pageName: .email),
            showLoader: false,
            showError: false
        )

        guard let emailResponse = response.entity else {
            viewProtocol?.showErrorMessage(DJSDKError.tryAgain.uiMessage)
            return
        }

        if emailResponse.duplicateReference ?? false {
            showMessage?(
                .success(
                    titleText: "Verification successful",
                    message:
                        "Your identification has been successfully verified."
                )
            )
            return
        }

        if emailResponse.continueVerification ?? false,
            let config = emailResponse.data
        {
            continueVerification(using: config)
        } else {
            runAfter { [weak self] in
                self?.setNextAuthStep()
            }
        }
    }

    private func continueVerification(using config: DJInitDataConfig) {
        if let verificationID = config.verificationID {
            preference.DJVerificationID = verificationID
        }

        if let sessionID = config.sessionID, sessionID.isNotEmpty {
            preference.DJRequestHeaders.updateValue(
                sessionID,
                forKey: "session"
            )
        }

        if let referenceID = config.referenceID, referenceID.isNotEmpty {
            preference.DJRequestHeaders.updateValue(
                referenceID,
                forKey: "reference"
            )
        }

        if let steps = config.steps?.by(statuses: [.notdone, .pending]),
            steps.isNotEmpty
        {
            preference.DJSteps = steps
        }

        runAfter { [weak self] in
            self?.setNextAuthStep()
        }
    }
}
