//
//  BaseViewModel.swift
//
//
//  Created by Isaac Iniongun on 08/12/2023.
//

import Foundation

class BaseViewModel {
    let eventsRemoteDatasource: EventsRemoteDatasourceProtocol
    let decisionRemoteDatasource: DecisionEngineRemoteDatasourceProtocol
    var preference: PreferenceProtocol
    var showLoader: ParamHandler<Bool>?
    var showMessage: ParamHandler<FeedbackConfig>?
    var showNextPage: NoParamHandler?
    var errorDoneAction: NoParamHandler?
    var verificationDoneAction: NoParamHandler?
    var showGovtIDPage: ParamHandler<DJGovernmentID>?
    
    init(
        eventsRemoteDatasource: EventsRemoteDatasourceProtocol = EventsRemoteDatasource(),
        decisionRemoteDatasource: DecisionEngineRemoteDatasourceProtocol = DecisionEngineRemoteDatasource(),
        preference: PreferenceProtocol = PreferenceImpl()
    ) {
        self.eventsRemoteDatasource = eventsRemoteDatasource
        self.decisionRemoteDatasource = decisionRemoteDatasource
        self.preference = preference
    }
    
    func postEvent(
        request: DJEventRequest,
        showLoader: Bool = true,
        showError: Bool = true,
        didSucceed: ParamHandler<EntityResponse<DJSuccessMessageEntity>>? = nil,
        didFail: ParamHandler<Error>? = nil
    ) {
        if showLoader {
            self.showLoader?(true)
        }
        eventsRemoteDatasource.postEvent(request: request) { [weak self] result in
            if showLoader {
                self?.showLoader?(false)
            }
            switch result {
            case let .success(eventsResponse):
                if eventsResponse.entity?.success == true {
                    didSucceed?(eventsResponse)
                } else {
                    if showError {
                        self?.showMessage?(.error(message: eventsResponse.entity?.msg ?? "Unable to post event: \(request.name)"))
                    }
                    didFail?(DJSDKError.tryAgain)
                }
            case let .failure(error):
                if showError {
                    self?.showMessage?(.error(message: error.uiMessage ?? "Unable to post event: \(request.name)"))
                }
                didFail?(error)
            }
        }
    }
    
    func setNextAuthStep(step: Int = 1, showNext: Bool = true) {
        let nextStep = preference.DJAuthStep.id + step
        guard let authStep = preference.DJSteps.first(where: { $0.id == nextStep }) else {
            makeVerificationDecision()
            return
        }
        preference.DJAuthStep = authStep
        kprint(preference.DJAuthStep.name.rawValue)
        if step > 0 && showNext {
            showNextPage?()
        }
    }
    
    func showErrorMessage(_ message: String, doneAction: NoParamHandler? = nil) {
        showLoader?(false)
        showMessage?(
            .error(
                message: message,
                doneAction: { [weak self] in
                    if let doneAction {
                        doneAction()
                    } else {
                        self?.errorDoneAction?()
                    }
                }
            )
        )
    }
    
    private func makeVerificationDecision() {
        showLoader?(true)
        decisionRemoteDatasource.makeVerificationDecision { [weak self] result in
            self?.showLoader?(false)
            switch result {
            case let .success(response):
                self?.didMakeVerificationDecision(response)
            case let .failure(error):
                self?.showErrorMessage(error.uiMessage)
            }
        }
    }
    
    private func didMakeVerificationDecision(_ response: EntityResponse<DecisionResponse>) {
        guard let decisionRes = response.entity, let decisionStatus = decisionRes.status else {
            showErrorMessage(response.entity?.reason ?? "Unable to make verification decision, please try again.")
            return
        }
        preference.DJAuthStep = .index
        let feedbackConfig = FeedbackConfig(
            feedbackType: decisionStatus.feedbackType,
            titleText: "Verification Status",
            message: decisionStatus.feedbackMessage,
            showNavControls: false,
            doneAction: verificationDoneAction
        )
        showMessage?(feedbackConfig)
    }
}
