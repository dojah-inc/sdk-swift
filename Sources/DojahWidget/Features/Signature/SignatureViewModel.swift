//
//  SignatureViewModel.swift
//
//
//  Created by Isaac Iniongun on 13/02/2024.
//

import Foundation

final class SignatureViewModel: BaseViewModel {
    lazy var signatureTitle = preference.DJAuthStep.config?.titleText ?? "Sign and confirm information"
    lazy var signatureInformation = preference.DJAuthStep.config?.information ?? ""
    
    override init(
        eventsRemoteDatasource: EventsRemoteDatasourceProtocol = EventsRemoteDatasource(),
        decisionRemoteDatasource: DecisionEngineRemoteDatasourceProtocol = DecisionEngineRemoteDatasource(),
        preference: PreferenceProtocol = PreferenceImpl()
    ) {
        super.init(
            eventsRemoteDatasource: eventsRemoteDatasource,
            decisionRemoteDatasource: decisionRemoteDatasource,
            preference: preference
        )
    }

    func didTapPrimaryButton(name: String, signatureData: Data) {
        confirm(name: name, signatureData: signatureData)
    }
    
    private func postStepEvent(name: DJEventName) {
        postEvent(
            request: .event(name: name, pageName: .signature),
            showLoader: false,
            showError: false
        )
    }

    func confirm(name: String, signatureData: Data) {
        let eventValue = "\(name)|\(signatureInformation)|data:image/jpeg;base64,\(signatureData.base64EncodedString())"
        postEvent(
            request: .init(name: .signature, value: eventValue),
            showLoader: true,
            didSucceed: { [weak self] _ in
                self?.postStepEvent(name: .stepCompleted)
                runAfter { [weak self] in
                    self?.setNextAuthStep()
                    self?.showLoader?(false)
                }
            },
            didFail: { [weak self] error in
                self?.showLoader?(false)
                self?.postStepEvent(name: .stepFailed)
                self?.showErrorMessage(error.localizedDescription)
            }
        )
    }
}
