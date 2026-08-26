//
//  File.swift
//  
//
//  Created by Isaac Iniongun on 25/01/2024.
//

import Foundation

final class UserDataViewModel: BaseViewModel {
    weak var viewProtocol: UserDataViewProtocol?
    private let remoteDatasource: UserDataRemoteDatasourceProtocol
    
    init(
        remoteDatasource: UserDataRemoteDatasourceProtocol = UserDataRemoteDatasource(),
        eventsRemoteDatasource: EventsRemoteDatasourceProtocol = EventsRemoteDatasource(),
        decisionRemoteDatasource: DecisionEngineRemoteDatasourceProtocol = DecisionEngineRemoteDatasource(),
        preference: PreferenceProtocol = PreferenceImpl()
    ) {
        self.remoteDatasource = remoteDatasource
        super.init(
            eventsRemoteDatasource: eventsRemoteDatasource,
            decisionRemoteDatasource: decisionRemoteDatasource,
            preference: preference
        )
    }
    
    func saveUserData(
        firstName: String,
        middleName: String? = nil,
        lastName: String,
        dob: String,
        onFailure: @escaping () -> Void? = ({ nil })
    ) {
        hideMessage()
        let params: DJParameters = [
            "mobile": "",
            "country": preference.DJCountryCode,
            "residence_country": preference.DJCountryCode,
            "first_name": firstName,
            "middle_name": middleName,
            "last_name": lastName,
            "dob": dob,
            "step_number": preference.DJAuthStep.id ?? 0
        ]
        
        showLoader?(true)
        remoteDatasource.saveUserData(params: params) { [weak self] res in
            switch res {
            case .success(let res):
                if res.entity?.success == true {
                    self?.postStepCompletedEvent()
                } else {
                    self?.postStepFailedEvent()
                    onFailure()
                    self?.showErrorMessage(res.entity?.msg ?? DJConstants.genericErrorMessage)
                }
            case .failure(let error):
                self?.postStepFailedEvent()
                onFailure()
                self?.showErrorMessage(error.uiMessage)
            }
        }
    }
    
    private func postStepCompletedEvent() {
        hideMessage()
        postEvent(
            request: .event(name: .stepCompleted, pageName: .userData),
            showLoader: false,
            showError: false,
            didSucceed: { [weak self] eventRes in
                self?.showLoader?(false)
                runAfter { [weak self] in
                    self?.setNextAuthStep()
                }
            },
            didFail: { [weak self] error in
                kprint("couldn't post 'user-data' event")
                self?.showLoader?(false)
                runAfter { [weak self] in
                    self?.setNextAuthStep()
                }
            }
        )
    }
    
    private func postStepFailedEvent() {
        postEvent(
            request: .event(name: .stepFailed, pageName: .userData),
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
}
