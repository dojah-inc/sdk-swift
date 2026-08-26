//
//  EmailViewModel.swift
//
//
//  Created by Isaac Iniongun on 02/05/2024.
//

import Foundation

final class EmailViewModel: BaseViewModel {
    weak var viewProtocol: EmailViewProtocol?
    private let validator: IInputValidator
    private var email: String = ""
    private var disposalEmailDomains = [String]()
    private var freeEmailDomains = [String]()
    
    init(
        validator: IInputValidator = InputValidatorImpl(),
        eventsRemoteDatasource: EventsRemoteDatasourceProtocol = EventsRemoteDatasource(),
        decisionRemoteDatasource: DecisionEngineRemoteDatasourceProtocol = DecisionEngineRemoteDatasource(),
        preference: PreferenceProtocol = PreferenceImpl()
    ) {
        self.validator = validator
        super.init(
            eventsRemoteDatasource: eventsRemoteDatasource,
            decisionRemoteDatasource: decisionRemoteDatasource,
            preference: preference
        )
        initialiseFreeAndDisposableEmailDomains()
    }
    
    private func initialiseFreeAndDisposableEmailDomains() {
        runOnBackgroundThread { [weak self] in
            guard let freeDomainsJsonData = jsonData(from: "free_email_domains"),
                  let disposableDomainsJsonData = jsonData(from: "disposable_email_domains")
            else {
                return
            }
            
            do {
                self?.freeEmailDomains = try freeDomainsJsonData.decode(into: [String].self)
                self?.disposalEmailDomains = try disposableDomainsJsonData.decode(into: [String].self)
                kprint("domians init")
            } catch {
                kprint("unable to init domains")
            }
        }
    }
    
    func setupPreAuthEmailAddress() {
        if(preference.preAuthEmailAddress != nil && preference.preAuthEmailAddress.isNotEmpty) {
            viewProtocol?.prefillEmail(email: preference.preAuthEmailAddress)
            self.didTapContinue(email: preference.preAuthEmailAddress)
        }
    }
    
    func didTapContinue(email: String) {
        self.email = email
        let result = validator.validate(email, for: .email)
        guard result.isValid else {
            viewProtocol?.showEmailError(result.message)
            return
        }
        viewProtocol?.hideEmailError()
        guard let emailDomain = email.components(separatedBy: "@").last else { return }
        let config = preference.DJAuthStep.config
        
        if config?.freeProvider == false, freeEmailDomains.contains(emailDomain) {
            viewProtocol?.showEmailError("Please enter a valid business email address.")
        } else if config?.disposable == false, disposalEmailDomains.contains(emailDomain) {
            viewProtocol?.showEmailError("Please avoid using a disposable email address.")
        } else {
            preference.DJOTPVerificationInfo = email
            
            if config?.verification ?? false {
                viewProtocol?.showVerifyController()
            } else {
                logEmailCollectedEvent()
            }
        }
    }
    
    private func logEmailCollectedEvent() {
        let eventRequest = DJEventRequest(
            name: .emailCollected,
            value: "\(email),Successful,\(preference.preAuthResponse?.widget?.duplicateCheck ?? false)"
        )
        showLoader?(true)
        eventsRemoteDatasource.postEmailCollectedEvent(request: eventRequest) { [weak self] result in
            self?.showLoader?(false)
            switch result {
            case let .success(eventsResponse):
                self?.didReceiveEmailCollectedResponse(eventsResponse)
            case let .failure(error):
                self?.viewProtocol?.showErrorMessage(error.uiMessage)
            }
        }
    }
    
    private func didReceiveEmailCollectedResponse(_ response: EntityResponse<EmailCollectedEventResponse>) {
        postEvent(
            request: .event(name: .stepCompleted, pageName: .email),
            showLoader: false,
            showError: false
        )
        
        guard let emailResponse = response.entity else {
            viewProtocol?.showErrorMessage(DJSDKError.tryAgain.uiMessage)
            return
        }
        
        guard emailResponse.success == true else {
            viewProtocol?.showErrorMessage(emailResponse.message ?? DJSDKError.tryAgain.uiMessage)
            return
        }
        
        if emailResponse.duplicateReference ?? false {
            showMessage?(
                .success(
                    titleText: "Verification successful",
                    message: "Your identification has been successfully verified."
                )
            )
            return
        }
        
        if emailResponse.continueVerification ?? false, let config = emailResponse.data {
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
            preference.DJRequestHeaders.updateValue(sessionID, forKey: "session")
        }
        
        if let referenceID = config.referenceID, referenceID.isNotEmpty {
            preference.DJRequestHeaders.updateValue(referenceID, forKey: "reference")
        }
        
        if let steps = config.steps?.by(statuses: [.notdone, .pending]), steps.isNotEmpty {
            preference.DJSteps = steps
        }
        
        runAfter { [weak self] in
            self?.setNextAuthStep()
        }
    }
}
