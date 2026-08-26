//
//  UtilityBillViewModel.swift
//  DojahWidget
//
//  Created by Sunday on 21/03/2026.
//
import Foundation

final class UtilityBillViewModel: BaseViewModel {

    private let livenessRemoteDatasource: LivenessRemoteDatasourceProtocol
    weak var viewProtocol: UtilityBillViewProtocol?
    var viewState: UtilityBillCaptureState = .capture
    var utilityBillImage: Data?

    private var pageName: DJPageName {
        preference.DJAuthStep.name ?? .index
    }
    
    private var documentURL: URL?
    private var docType = "image"
    var isDocumentUpload: Bool {
        [.upload].contains(viewState)
    }
    
    init(
        livenessRemoteDatasource: LivenessRemoteDatasourceProtocol = LivenessRemoteDatasource(),
        eventsRemoteDatasource: EventsRemoteDatasourceProtocol = EventsRemoteDatasource(),
        decisionRemoteDatasource: DecisionEngineRemoteDatasourceProtocol = DecisionEngineRemoteDatasource(),
        preference: PreferenceProtocol = PreferenceImpl()
    ) {
        self.livenessRemoteDatasource = livenessRemoteDatasource
        super.init(
            eventsRemoteDatasource: eventsRemoteDatasource,
            decisionRemoteDatasource: decisionRemoteDatasource,
            preference: preference
        )
    }
    
    func didTapContinue() {
        switch viewState {
        case .capture:
            break
        case .preview:
            uploadDocument()
            break
        case .upload:
            updateViewState()
        }
    }
    
    func updateImageData(_ data: Data) {
        docType = "image"
        utilityBillImage = data
    }
    
    func updateIDData(from fileURL: URL) {
        docType = "pdf"
        
        let data = fileURL.localFileData
        utilityBillImage = data
    }
    
    private func imageAnalysisOrCheckOrDocumentUploadDidFail(_ error: DJSDKError) {
        postStepFailedEvent()
        showErrorMessage(error.uiMessage)
    }
    
    func updateViewState() {
        switch viewState {
        case .upload:
            makeCheckRequest()
            break
        case .capture:
            viewState = .preview
        case .preview:
            break
        }
        runOnMainThread { [weak self] in
            self?.viewProtocol?.updateUI()
        }
    }
    
    private func makeCheckRequest() {
        guard let utilityBillImage else {
            showToast(message: "Capture or choose a valid image", type: .error)
            return
        }
        
        if isDocumentUpload {
            showLoader?(true)
        }
        var params: DJParameters = [
            "utility_bill_image": utilityBillImage.base64EncodedString().encrypted() ?? "",
            "param": "utility_bill",
            "doc_type": docType
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
    
    public func autoUploadGovId(imageBase64: String,idType:String,docType:String) {

        let params: DJParameters = [
            "utility_bill_image": imageBase64.encrypted(),
            "param": "utility_bill",
            "doc_type": docType,
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
        guard let checkResponse = response.entity else {
            showLoader?(false)
            showToast(message: DJConstants.genericErrorMessage, type: .error)
            return
        }
        
        if checkResponse.match ?? false {
            postStepCompletedEvent()
            runAfter { [weak self] in
                self?.setNextAuthStep()
            }
        } else {
            showLoader?(false)
            postEvent(
                request: .stepFailed(errorCode: .imageCheckFailedAfterMaxRetries),
                showLoader: false,
                showError: false
            )
            runAfter { [weak self] in
                self?.setNextAuthStep()
            }
            
            showErrorMessage(checkResponse.reason ?? "Address verification failed")
        }
    }
    
    private func uploadDocument() {
        guard let fileData = documentURL?.localFileData?.base64EncodedString() ?? utilityBillImage?.base64EncodedString() else { return }
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
