//
//  GovtIDOptionsViewModel.swift
//
//
//  Created by Isaac Iniongun on 01/02/2024.
//

import Foundation

final class GovtIDOptionsViewModel: BaseViewModel {
    var identificationTypes = [DJGovernmentID]()
    var selectedID: DJGovernmentID?
    
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
        identificationTypes = GovernmentIDFactory.getGovernmentIDs(for: .id, preference: preference)
    }
    
    func didChooseIdentificationType(at index: Int) {
        selectedID = identificationTypes[index]
    }
    
    func didTapContinue() {
        guard let selectedID else { return }
        print(selectedID)
        showLoader?(true)
        postEvent(
            request: .init(name: .verificationTypeSelected, value: selectedID.value ?? "ID"),
            showLoader: false,
            didSucceed: { [weak self] _ in
                self?.postVerificationModeSelected()
            },
            didFail: { [weak self] _ in
                self?.showLoader?(false)
            }
        )
    }
    
    private func postVerificationModeSelected() {
        postEvent(
            request: .init(name: .verificationModeSelected, value: "LIVENESS"),
            showLoader: false,
            didSucceed: { [weak self] _ in
                self?.postStepCompletedEvent()
            },
            didFail: { [weak self] _ in
                self?.showLoader?(false)
            }
        )
    }
    
    private func postStepCompletedEvent() {
        postEvent(
            request: .event(name: .stepCompleted, pageName: .idOptions),
            showLoader: false,
            didSucceed: { [weak self] _ in
                self?.didPostCompletedEvent()
            },
            didFail: { [weak self] _ in
                self?.showLoader?(false)
            }
        )
    }
    
    private func didPostCompletedEvent() {
        showLoader?(false)
        setNextAuthStep(showNext: false)
        showGovtIDPage?(selectedID!)
    }
}
