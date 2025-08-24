//
//  DJGovernmentDataViewModel.swift
//
//
//  Created by Isaac Iniongun on 12/12/2023.
//

import Foundation

final class DJGovernmentDataViewModel: BaseViewModel {
    weak var viewProtocol: GovernmentDataViewProtocol?
    private let governmentDataRemoteDatasource:
        GovernmentDataRemoteDatasourceProtocol
    var governmentIDs = [DJGovernmentID]()
    var governmentIDVerificationMethods = [DJGovernmentID]()
    var allGovernmentIDVerificationMethods = [DJGovernmentID]()
    var selectedGovernmentID: DJGovernmentID?
    var selectedGovernmentIDVerificationMethod: DJGovernmentID?
    var idNumber = ""
    private var lookupEntity: GovernmentDataLookupEntity? = nil
    private var pricingServices: [String] {
        PricingServicesFactory.shared.services(
            governmentIDType: selectedGovernmentID?.idType,
            verificationMethod: selectedGovernmentIDVerificationMethod?
                .verificationMethod
        )
    }

    init(
        remoteDatasource: GovernmentDataRemoteDatasourceProtocol =
            GovernmentDataRemoteDatasource()
    ) {
        self.governmentDataRemoteDatasource = remoteDatasource
        super.init()
        governmentIDs = GovernmentIDFactory.getGovernmentIDs(
            for: .governmentData,
            preference: preference
        )
        
        allGovernmentIDVerificationMethods =
            GovernmentIDFactory.getVerificationMethods(
                for: .governmentData,
                preference: preference
            )
        
        governmentIDVerificationMethods = allGovernmentIDVerificationMethods
    }

    func didChooseGovernmentData(at index: Int, type: GovernmentDataType) {
        hideMessage()
        switch type {
        case .id:
            selectedGovernmentID = governmentIDs[index]
            viewProtocol?.showGovtIDNumberTextField()
            refreshVerificationMethods()
        case .verificationMethod:
            selectedGovernmentIDVerificationMethod =
                governmentIDVerificationMethods[index]
            preference.DJSelectedGovernmentIDVerificationMethod =
                selectedGovernmentIDVerificationMethod
            sendVerificationMethodSelectedEvent()
        }
    }

    private func refreshVerificationMethods() {
        selectedGovernmentIDVerificationMethod = nil
        if [.dl, .dlID, .ngDLI].contains(selectedGovernmentID?.idType) {
            governmentIDVerificationMethods =
                allGovernmentIDVerificationMethods.filter {
                    $0.name?.insensitiveContains("selfie") ?? false
                }
        } else {
            governmentIDVerificationMethods = allGovernmentIDVerificationMethods
        }
        viewProtocol?.updateVerificationMethods()
    }

    private func sendVerificationMethodSelectedEvent() {
        guard
            let modeParam = selectedGovernmentIDVerificationMethod?
                .verificationModeParam
        else { return }
        postEvent(
            request: .init(name: .verificationModeSelected, value: modeParam),
            showLoader: false,
            showError: false
        )
    }

    func didTapContinue() {
        guard let selectedGovernmentID else { return }
        showLoader?(true)
        hideMessage()
        let eventRequest = DJEventRequest(
            name: .verificationTypeSelected,
            value: "\(selectedGovernmentID.idTypeParam),\(idNumber)"
        )
        eventsRemoteDatasource.postEvent(request: eventRequest) {
            [weak self] result in
            switch result {
            case let .success(successResponse):
                if successResponse.entity?.success ?? false {
                    self?.lookupGovernmentData()
                } else {
                    self?.showErrorMessage(
                        successResponse.entity?.msg
                            ?? "Unable to send verificationTypeSelected event"
                    )
                }
            case let .failure(error):
                self?.showErrorMessage(error.uiMessage)
            }
        }
    }

    private func lookupGovernmentData() {
        hideMessage()
        guard let idEnum = selectedGovernmentID?.idEnum,
            let idType = DJGovernmentIDType(rawValue: idEnum)
        else { return }
        governmentDataRemoteDatasource.lookupID(
            number: idNumber,
            idType: idType
        ) { [weak self] result in
            switch result {
            case let .success(lookupResponse):
                if let response = lookupResponse.entity {
                    self?.lookupEntity = response
                    self?.sendVerificationsPageConfigCollectedEvent()
                    self?.postGovernmentDataCollectedEvent()
                } else {
                    self?.postStepFailedEvent()
                    self?.showErrorMessage(
                        DJSDKError.invalidIDNotFoundGovernmentData(idType)
                            .uiMessage
                    )
                }
            case let .failure(error):
                self?.postStepFailedEvent()
                if error == .invalidIDThirdPartyFailure {
                    self?.showErrorMessage(
                        DJSDKError.invalidIDNotFoundThirdPartyMessage(idType)
                            .uiMessage
                    )
                } else if error == .invalidIDNotFoundThirdParty {
                    self?.showErrorMessage(
                        DJSDKError.invalidIDNotFoundGovernmentData(idType)
                            .uiMessage
                    )
                } else {
                    self?.showErrorMessage(error.uiMessage)
                }
            }
        }
    }

    private func postStepFailedEvent() {
        let request: DJEventRequest = .stepFailed(
            errorCode: .invalidIDNotFound,
            services: pricingServices
        )
        postEvent(
            request: request,
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

    private func postGovernmentDataCollectedEvent() {
        guard let lookupEntity, let selectedGovernmentID else { return }
        let eventRequest = DJEventRequest(
            name: .customerGovernmentDataCollected,
            value: lookupEntity.dataCollectedParam(
                idEnum: selectedGovernmentID.idEnum.orEmpty,
                countryCode: preference.DJCountryCode
            )
        )
        eventsRemoteDatasource.postEvent(request: eventRequest) {
            [weak self] result in
            switch result {
            case let .success(successResponse):
                if successResponse.entity?.success ?? false {
                    self?.postGovernmentImageCollectedEvent()
                } else {
                    self?.showErrorMessage(
                        successResponse.entity?.msg
                            ?? "Unable to send customerGovernmentDataCollected event"
                    )
                }
            case let .failure(error):
                self?.showErrorMessage(error.uiMessage)
            }
        }
    }

    private func postGovernmentImageCollectedEvent() {
        guard let lookupEntity,
            let image = lookupEntity.image ?? lookupEntity.photo
        else { return }
        eventsRemoteDatasource.postEvent(
            request: .init(name: .governmentImageCollected, value: image)
        ) { [weak self] result in
            switch result {
            case let .success(successResponse):
                if successResponse.entity?.success ?? false {
                    self?.postStepCompletedEvent()
                } else {
                    self?.showErrorMessage(
                        successResponse.entity?.msg
                            ?? "Unable to send governmentImageCollected event"
                    )
                }
            case let .failure(error):
                self?.showErrorMessage(error.uiMessage)
            }
        }
    }

    private func postStepCompletedEvent() {
        let request: DJEventRequest = .event(
            name: .stepCompleted,
            pageName: .governmentData,
            services: pricingServices
        )
        eventsRemoteDatasource.postEvent(request: request) {
            [weak self] result in
            switch result {
            case let .success(successResponse):
                if successResponse.entity?.success ?? false {
                    self?.didSendCompletedEvent()
                } else {
                    self?.showErrorMessage(
                        successResponse.entity?.msg
                            ?? "Unable to send stepCompleted::government-data event"
                    )
                }
            case let .failure(error):
                self?.showErrorMessage(error.uiMessage)
            }
        }
    }
    //Whatsapp
    private func didSendCompletedEvent() {
        showLoader?(false)
        if selectedGovernmentIDVerificationMethod?.verificationModeParam
            == "OTP"
            || selectedGovernmentIDVerificationMethod?.verificationModeParam
                == "Whatsapp"
        {
            guard let lookupEntity,
                let phoneNumber = lookupEntity.phoneNumber1
                    ?? lookupEntity.phoneNumber2
            else { return }
            preference.DJOTPVerificationInfo = phoneNumber
        }
        
        runAfter { [weak self] in
            self?.setNextAuthStep()
        }
    }

    private func sendVerificationsPageConfigCollectedEvent() {
        guard
            let modeParam = selectedGovernmentIDVerificationMethod?
                .verificationModeParam,
            let phoneNumber = lookupEntity?.phoneNumber
        else { return }
        postEvent(
            request: .init(
                name: .verificationsPageConfigCollected,
                value: "\(modeParam),\(phoneNumber)"
            ),
            showLoader: false,
            showError: false
        )
    }
}
