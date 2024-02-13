//
//  BusinessDataViewModel.swift
//
//
//  Created by Isaac Iniongun on 13/02/2024.
//

import Foundation

final class BusinessDataViewModel: BaseViewModel {
    weak var viewProtocol: BusinessDataViewProtocol?
    private let remoteDatasource: BusinessDataRemoteDatasourceProtocol
    var documentTypes = [DJGovernmentID]()
    var selectedDocument: DJGovernmentID?
    
    init(remoteDatasource: BusinessDataRemoteDatasourceProtocol = BusinessDataRemoteDatasource()) {
        self.remoteDatasource = remoteDatasource
        super.init()
        documentTypes = GovernmentIDFactory.getBusinessDocumentTypes(preference: preference)
    }
    
    func didChooseDocumentType(at index: Int) {
        selectedDocument = documentTypes[index]
        viewProtocol?.updateNumberTextfield()
    }
    
    func verifyBusiness(name: String, number: String) {
        guard let selectedDocument else {
            showToast(message: "Choose a document type", type: .error)
            return
        }
        
        let eventValue = "\(selectedDocument.idEnum.orEmpty),\(number)"
        postEvent(
            request: .init(name: .verificationTypeSelected, value: eventValue),
            showLoader: false,
            showError: false
        )
        
        guard let businessDataType = BusinessDataType(rawValue: selectedDocument.idEnum.orEmpty) else {
            showToast(message: DJConstants.genericErrorMessage, type: .error)
            return
        }
        
        let params = [
            businessDataType.verificationRequestParam: number,
            "company_name": name
        ]
        
        showLoader?(true)
        remoteDatasource.verify(
            type: businessDataType,
            params: params
        ) { [weak self] result in
            switch result {
            case let .success(response):
                self?.didGetVerificationResponse(response, businessDataType: businessDataType)
            case let .failure(error):
                self?.showLoader?(false)
                self?.postPageEvent(success: false)
                self?.showErrorMessage(error.uiMessage)
            }
        }
    }
    
    private func didGetVerificationResponse(_ response: EntityResponse<BusinessDataResponse>, businessDataType: BusinessDataType) {
        guard let businessDataResponse = response.entity else {
            postPageEvent(success: false)
            return
        }
        let values = [businessDataResponse.business, businessDataType.rawValue, preference.DJCountryCode, businessDataResponse.companyName]
        let eventValue = values.compactMap { $0 }.joined(separator: ",")
        postEvent(
            request: .init(name: .customerBusinessDataCollected, value: eventValue),
            showLoader: false,
            showError: false,
            didSucceed: { [weak self] _ in
                self?.showLoader?(false)
                self?.postPageEvent()
                self?.setNextAuthStep()
            },
            didFail: { [weak self] _ in
                self?.showLoader?(false)
                self?.postPageEvent(success: false)
                self?.setNextAuthStep()
            }
        )
    }
    
    private func postPageEvent(success: Bool = true) {
        postEvent(
            request: .event(name: success ? .stepCompleted : .stepFailed, pageName: .businessData),
            showLoader: false,
            showError: false
        )
    }
}
