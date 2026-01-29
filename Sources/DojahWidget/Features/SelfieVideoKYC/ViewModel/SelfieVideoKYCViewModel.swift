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
        viewState: SelfieVideoKYCViewState = .capture
    ) {
        self.remoteDatasource = remoteDatasource
        self.verificationMethod = verificationMethod
        self.viewState = viewState
        super.init()
    }
    
    func analyseImage() {
        guard let imageData else { return }
        showLoader?(true)
        let params = [
            "image": imageData.base64EncodedString().encrypted(),
            "image_type": "selfie" //pass 'id' for government-issued-id
        ]
        imageAnalysisTries += 1
        remoteDatasource.performImageAnalysis(params: params) { [weak self] result in
            switch result {
            case let .success(response):
                self?.didGetImageAnalysisResponse(response)
            case let .failure(error):
                self?.imageAnalysisOrCheckDidFail(error: error)
            }
        }
    }
    
    private func didGetImageAnalysisResponse(_ response: EntityResponse<ImageAnalysisResponse>) {
        //[.governmentDataVerification, .governmentData].contains(preference.DJAuthStep.name)
        guard let analysisResponse = response.entity else {
            showLoader?(false)
            viewProtocol?.showSelfieImageError(message: DJConstants.genericErrorMessage)
            return
        }
        
        if analysisResponse.face?.faceDetected == false {
            showLoader?(false)
            viewProtocol?.showSelfieImageError(message: "No face detected")
            return
        }
        
        if analysisResponse.face?.multifaceDetected == true {
            showLoader?(false)
            viewProtocol?.showSelfieImageError(message: "Multiple faces detected")
            return
        }
        
        if analysisResponse.face?.quality?.brightness ?? 0 <= preference.DJAuthStep.config?.brightnessThreshold ?? 40 {
            showLoader?(false)
            viewProtocol?.showSelfieImageError(message: "Not bright enough. Please move to a brighter area")
            return
        }
        
//        if preference.DJAuthStep.config?.glassesCheck ?? true !=
//            (analysisResponse.face?.details?.eyeglasses?.value ?? false || analysisResponse.face?.details?.sunglasses?.value ?? false) {
//            showLoader?(false)
//            viewProtocol?.showSelfieImageError(message: "Glasses detected. Retake selfie without your glasses")
//            return
//        }
        
        performImageCheck()
    }
    
    private func imageAnalysisOrCheckDidFail(error: DJSDKError) {
        postCheckFailedEvent()
        if error == .imageCheckOrAnalysisError {
            viewProtocol?.showSelfieImageError(message: DJSDKError.selfieVideoCouldNotBeCaptured.uiMessage)
        } else {
            viewProtocol?.showSelfieImageError(message: error.uiMessage)
        }
    }
    
    private func performImageCheck() {
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
            viewProtocol?.showSelfieImageError(message: DJSDKError.selfieVideoCouldNotBeCaptured.uiMessage)
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
                runAfter { [weak self] in
                    self?.setNextAuthStep()
                }
            }
            postCheckFailedEvent()
            viewProtocol?.showSelfieImageError(message: checkResponse.reason ?? "Selfie verification failed")
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
