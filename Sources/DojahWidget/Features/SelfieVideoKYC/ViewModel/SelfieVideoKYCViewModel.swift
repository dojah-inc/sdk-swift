//
//  SelfieVideoKYCViewModel.swift
//
//
//  Created by Isaac Iniongun on 31/10/2023.
//

import Foundation

final class SelfieVideoKYCViewModel: BaseViewModel {
    
    private enum Constants {
        static let imageAnalysisMaxTries = 3
        static let imageCheckMaxTries = 2
    }
    
    weak var viewProtocol: SelfieVideoKYCViewProtocol?
    private let remoteDatasource: LivenessRemoteDatasourceProtocol
    let verificationMethod: GovtIDVerificationMethod
    var viewState: SelfieVideoKYCViewState
    var imageData: Data?
    private var imageAnalysisTries = 0
    private var imageCheckMaxTries = 0
    private var pricingServices: [String] {
        PricingServicesFactory.shared.services(
            verificationMethod: verificationMethod
        )
    }
    
    init(
        remoteDatasource: LivenessRemoteDatasourceProtocol = LivenessRemoteDatasource(),
        verificationMethod: GovtIDVerificationMethod = .selfie,
        viewState: SelfieVideoKYCViewState = .capture,
        eventsRemoteDatasource: EventsRemoteDatasourceProtocol = EventsRemoteDatasource(),
        decisionRemoteDatasource: DecisionEngineRemoteDatasourceProtocol = DecisionEngineRemoteDatasource(),
        preference: PreferenceProtocol = PreferenceImpl()
    ) {
        self.remoteDatasource = remoteDatasource
        self.verificationMethod = verificationMethod
        self.viewState = viewState
        super.init(
            eventsRemoteDatasource: eventsRemoteDatasource,
            decisionRemoteDatasource: decisionRemoteDatasource,
            preference: preference
        )
    }
    
    private func imageAnalysisOrCheckDidFail(error: DJSDKError) {
        postCheckFailedEvent()
        
        runAfter { [weak self] in
            self?.setNextAuthStep()
        }
//        if error == .imageCheckOrAnalysisError {
//            viewProtocol?.showSelfieImageError(message: DJSDKError.selfieVideoCouldNotBeCaptured.uiMessage)
//        } else {
//            viewProtocol?.showSelfieImageError(message: error.uiMessage)
//        }
    }
    
    func performImageCheck() {
        imageCheckMaxTries += 1
        guard let imageData else { return }
        let params: DJParameters = [
            "image": imageData.base64EncodedString().encrypted(),
            "param": "face", // pass 'NG{country alpha2 code}-PASS' when using passport. this is gotten from the selected id from the identification map
            // pass 'BUSINESS' for business ID
            "selfie_type": "single",
            "doc_type": "image",
            "continue_verification": imageAnalysisTries >= Constants.imageAnalysisMaxTries
        ]
        showLoader?(true)
        remoteDatasource.performImageCheck(params: params) { [weak self] result in
            switch result {
            case let .success(response):
                self?.didGetImageCheckResponse(response)
            case let .failure(error):
                self?.imageAnalysisOrCheckDidFail(error: error)
            }
        }
    }
    
    private func didGetImageCheckResponse(_ response: EntityResponse<ImageCheckResponse>) {
        if imageAnalysisTries >= Constants.imageAnalysisMaxTries {
            postEvent(
                request: .event(name: .stepFailed, pageName: .governmentDataVerification, services: pricingServices),
                showLoader: false,
                showError: false
            )
        }
        
        guard let checkResponse = response.entity else {
            showLoader?(false)
            postCheckFailedEvent()
            
            runAfter { [weak self] in
                self?.setNextAuthStep()
            }
            return
        }
        
        if checkResponse.match ?? false {
            showLoader?(false)
            postEvent(
                request: .event(name: .stepCompleted, pageName: .governmentDataVerification, services: pricingServices),
                showLoader: false,
                showError: false
            )
            
            runAfter { [weak self] in
                self?.setNextAuthStep()
            }
        } else {
            showLoader?(false)
            if imageCheckMaxTries > Constants.imageCheckMaxTries {
                postEvent(
                    request: .stepFailed(errorCode: .imageCheckFailedAfterMaxRetries, services: pricingServices),
                    showLoader: false,
                    showError: false
                )
            }
            postCheckFailedEvent()
            runAfter { [weak self] in
                self?.setNextAuthStep()
            }
        }
    
    }
    
    private func postCheckFailedEvent() {
        postEvent(
            request: .event(name: .stepFailed, pageName: .governmentDataVerification, services: pricingServices),
            showLoader: false,
            showError: false
        )
    }
    
    private func imageCheckDidSucceed() {
        postEvent(
            request: .event(name: .stepCompleted, pageName: .governmentDataVerification, services: pricingServices),
            showLoader: false,
            showError: false
        )
        
        remoteDatasource.verifyImage(params: [:]) { [weak self] result in
            switch result {
            case .success(_):
                self?.showLoader?(false)
                runAfter { [weak self] in
                    self?.setNextAuthStep()
                }
            case let .failure(error):
                self?.viewProtocol?.showSelfieImageError(message: error.uiMessage)
            }
        }
    }
    
}
