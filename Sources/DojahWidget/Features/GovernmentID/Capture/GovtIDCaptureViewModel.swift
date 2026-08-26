//
//  GovtIDCaptureViewModel.swift
//
//
//  Created by Isaac Iniongun on 01/02/2024.
//

import Foundation

final class GovtIDCaptureViewModel: BaseViewModel {
    
    private enum Constants {
        static let imageAnalysisMaxTries = 3
        static let imageCheckMaxTries = 2
    }
    
    let selectedID: DJGovernmentID
    private let livenessRemoteDatasource: LivenessRemoteDatasourceProtocol
    weak var viewProtocol: GovtIDCaptureViewProtocol?
    var viewState: GovtIDCaptureViewState = .captureFront
    var idFrontImageData: Data?
    var idBackImageData: Data?
    private var imageAnalysisTries = 0
    private var imageCheckMaxTries = 0
    private var isFrontAndBackID: Bool {
        selectedID.idType?.isFrontAndBack ?? false
    }
    private var pageName: DJPageName {
        preference.DJAuthStep.name ?? .index
    }
    private var isBusinessID: Bool {
        pageName == .businessID
    }
    private var imageCheckParam: String {
        isBusinessID ? "BUSINESS" : selectedID.idType?.rawValue ?? "ID"
    }
    var idName: String {
        isBusinessID ? "CAC Document" : selectedID.name ?? ""
    }
    private var documentURL: URL?
    private var docType = "image"
    var isDocumentUpload: Bool {
        [.uploadFront, .uploadBack, .uploadDocument, .uploadCACDocument].contains(viewState)
    }
    
    init(
        selectedID: DJGovernmentID = .empty,
        livenessRemoteDatasource: LivenessRemoteDatasourceProtocol = LivenessRemoteDatasource(),
        eventsRemoteDatasource: EventsRemoteDatasourceProtocol = EventsRemoteDatasource(),
        decisionRemoteDatasource: DecisionEngineRemoteDatasourceProtocol = DecisionEngineRemoteDatasource(),
        preference: PreferenceProtocol = PreferenceImpl()
    ) {
        self.selectedID = selectedID
        self.livenessRemoteDatasource = livenessRemoteDatasource
        super.init(
            eventsRemoteDatasource: eventsRemoteDatasource,
            decisionRemoteDatasource: decisionRemoteDatasource,
            preference: preference
        )
        initViewState()
    }
    
    private func initViewState() {
        switch preference.DJAuthStep.name {
        case .id:
            viewState = .captureFront
        case .businessID:
            viewState = .captureCACDocument
        case .additionalDocument:
            viewState = .captureDocument
        default:
            break
        }
    }
    
    func didTapContinue() {
        switch viewState {
        case .captureFront, .captureBack, .captureCACDocument, .captureDocument:
            break
        case .previewFront:
            guard let idFrontImageData else {
                showToast(message: "Capture or choose a valid image", type: .error)
                return
            }
            processIdImage()
        case .previewBack:
            guard let idBackImageData else {
                showToast(message: "Capture or choose a valid image", type: .error)
                return
            }
            processIdImage()
        case .previewCACDocument, .uploadCACDocument:
            makeCheckRequest()
        case .previewDocument, .uploadDocument:
            uploadDocument()
        case .uploadFront, .uploadBack:
            updateViewState()
        }
    }
    
    func updateImageData(_ data: Data) {
        docType = "image"
        if isFrontAndBackID {
            if viewState == .captureFront {
                idFrontImageData = data
            } else {
                idBackImageData = data
            }
        } else {
            idFrontImageData = data
        }
    }
    
    func updateIDData(from fileURL: URL) {
        let ext = fileURL.pathExtension.lowercased()
        let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "gif", "bmp", "tiff", "tif", "webp"]
        docType = imageExtensions.contains(ext) ? "image" : "pdf"
        if pageName == .additionalDocument {
            documentURL = fileURL
            return
        }
        let data = fileURL.localFileData
        if isFrontAndBackID {
            if viewState == .uploadFront {
                idFrontImageData = data
            } else {
                idBackImageData = data
            }
        } else {
            idFrontImageData = data
        }
    }
    
    private func imageAnalysisOrCheckOrDocumentUploadDidFail(_ error: DJSDKError) {
        postStepFailedEvent()
        if [.imageCheckOrAnalysisError, .govtIDCouldNotBeCaptured].contains(error) {
            showErrorMessage(DJSDKError.govtIDCouldNotBeCaptured.uiMessage)
        } else {
            showErrorMessage(error.uiMessage)
        }
    }
    
    private func processIdImage() {
        if (selectedID.idType?.isNGNIN == true) || isBusinessID {
            makeCheckRequest()
            return
        }
        
        if isFrontAndBackID {
            updateViewState()
        } else {
            makeCheckRequest()
        }
    }
    
    func updateViewState() {
        switch viewState {
        case .uploadFront:
            imageAnalysisTries = 0
            if isFrontAndBackID {
                viewState = .uploadBack
            } else {
                makeCheckRequest()
            }
        case .uploadBack:
            imageAnalysisTries = 0
            makeCheckRequest()
        case .captureFront:
            viewState = .previewFront
        case .captureBack:
            viewState = .previewBack
        case .previewFront:
            imageAnalysisTries = 0
            viewState = .captureBack
        case .previewBack:
            imageAnalysisTries = 0
            makeCheckRequest()
        case .captureCACDocument:
            viewState = .previewCACDocument
        case .captureDocument:
            viewState = .previewDocument
        case .uploadDocument, .previewDocument, .uploadCACDocument, .previewCACDocument:
            break
        }
        runOnMainThread { [weak self] in
            self?.viewProtocol?.updateUI()
        }
    }
    
    private func makeCheckRequest() {
        imageCheckMaxTries += 1
        guard let idFrontImageData else {
            showToast(message: "Capture or choose a valid image", type: .error)
            return
        }
        showLoader?(true)
        var params: DJParameters = [
            "image": idFrontImageData.base64EncodedString().encrypted() ?? "",
            "param": imageCheckParam,
            "doc_type": docType,
            "continue_verification": imageAnalysisTries >= Constants.imageAnalysisMaxTries
        ]
        if isFrontAndBackID, let idBackImageData {
            params["image2"] = idBackImageData.base64EncodedString().encrypted()
        }
        
        livenessRemoteDatasource.performImageCheck(params: params) { [weak self] result in
            guard let self else { return }
            if self.isDocumentUpload {
                self.showLoader?(false)
            }
            switch result {
            case let .success(response):
                self.didGetCheckRequestResponse(response)
            case let .failure(error):
                self.imageAnalysisOrCheckOrDocumentUploadDidFail(error)
            }
        }
    }
    
    public func autoUploadGovId(imageBase64: String,idType:String,docType:String) {

        let params: DJParameters = [
            "image": imageBase64.encrypted(),
            "param": idType,
            "doc_type": docType,
            "continue_verification": false
        ]
        
        livenessRemoteDatasource.performImageCheck(params: params) { [weak self] result in
            guard let self else { return }
            if self.isDocumentUpload {
                self.showLoader?(false)
            }
            switch result {
            case let .success(response):
                self.didGetCheckRequestResponse(response)
            case let .failure(error):
                self.imageAnalysisOrCheckOrDocumentUploadDidFail(error)
            }
        }
    }
    
    private func didGetCheckRequestResponse(_ response: EntityResponse<ImageCheckResponse>) {
        if imageAnalysisTries >= Constants.imageAnalysisMaxTries {
            postEvent(
                request: .event(name: .stepFailed, pageName: pageName),
                showLoader: false,
                showError: false
            )
        }
        
        guard let checkResponse = response.entity else {
            showLoader?(false)
            showToast(message: DJConstants.genericErrorMessage, type: .error)
            return
        }
        
        if checkResponse.match ?? false {
            showLoader?(true)
            checkRequestDidSucceed()
        } else {
            showLoader?(false)
            if imageCheckMaxTries > Constants.imageCheckMaxTries {
                postEvent(
                    request: .stepFailed(errorCode: .imageCheckFailedAfterMaxRetries),
                    showLoader: false,
                    showError: false
                )
                runAfter { [weak self] in
                    self?.setNextAuthStep()
                }
            }
            showErrorMessage(checkResponse.reason ?? "\(idName) verification failed")
        }
    }
    
    private func checkRequestDidSucceed() {
        imageAnalysisTries = 0
        imageCheckMaxTries = 0
        postStepCompletedEvent()
        livenessRemoteDatasource.verifyImage(params: [:]) { [weak self] result in
            switch result {
            case .success:
                self?.showLoader?(false)
                runAfter { [weak self] in
                    self?.setNextAuthStep()
                }
            case let .failure(error):
                self?.showErrorMessage(error.uiMessage)
            }
        }
    }
    
    private func uploadDocument() {
        guard let fileData = documentURL?.localFileData?.base64EncodedString() ?? idFrontImageData?.base64EncodedString() else { return }
        let params = [
            "file_base64": fileData.encrypted(),
            "file_type": documentURL?.pathExtension ?? "image",
            "file_name": documentURL?.lastPathComponent ?? "jpg",
            "title": "Untitled"
        ]
        showLoader?(true)
        livenessRemoteDatasource.uploadDocument(params: params) { [weak self] result in
            self?.showLoader?(false)
            switch result {
            case let .success(response):
                self?.didUploadDocument(response)
            case let .failure(error):
                self?.imageAnalysisOrCheckOrDocumentUploadDidFail(error)
            }
        }
    }
    
    private func didUploadDocument(_ response: SuccessEntityResponse) {
        if response.entity?.success == true {
            postStepCompletedEvent()
            setNextAuthStep()
        } else {
            postStepFailedEvent()
            showErrorMessage(DJSDKError.govtIDCouldNotBeCaptured.uiMessage)
        }
    }
    
    private func postStepCompletedEvent() {
        postEvent(
            request: .event(name: .stepCompleted, pageName: pageName),
            showLoader: false,
            showError: false
        )
    }
    
    private func postStepFailedEvent() {
        postEvent(
            request: .event(name: .stepFailed, pageName: pageName),
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
    
    public func downloadImageAndConvertToBase64(from urlString: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error downloading image: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }

            let base64String = data.base64EncodedString()
            completion(base64String)
        }

        task.resume()
    }

}
