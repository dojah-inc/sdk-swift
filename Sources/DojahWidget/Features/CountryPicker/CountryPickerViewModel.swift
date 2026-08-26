//
//  CountryPickerViewModel.swift
//
//
//  Created by Isaac Iniongun on 02/12/2023.
//

import Foundation

final class CountryPickerViewModel: BaseViewModel {
    weak var viewProtocol: CountryPickerViewProtocol?
    private let countriesLocalDatasource: CountriesLocalDatasourceProtocol
    private var allCountries = [DJCountryDB]()
    var countries = [DJCountryDB]()
    private var countrySelected = false
    private var selectedCountry: DJCountryDB?
    private lazy var preAuthCountries = preference.preAuthResponse?.widget?.countries
    
    init(
        countriesLocalDatasource: CountriesLocalDatasourceProtocol = CountriesLocalDatasource(),
        eventsRemoteDatasource: EventsRemoteDatasourceProtocol = EventsRemoteDatasource(),
        decisionRemoteDatasource: DecisionEngineRemoteDatasourceProtocol = DecisionEngineRemoteDatasource(),
        preference: PreferenceProtocol = PreferenceImpl()
    ) {
        self.countriesLocalDatasource = countriesLocalDatasource
        // Initialize simple stored properties before using self
        self.allCountries = []
        self.countries = []
        super.init(
            eventsRemoteDatasource: eventsRemoteDatasource,
            decisionRemoteDatasource: decisionRemoteDatasource,
            preference: preference
        )

        // Compute iso codes without capturing self in a closure
        let isoCodes: [String] = {
            guard let pages = preference.preAuthResponse?.widget?.pages as? [DJPage] else { return ["ng"] }
            let regex = try? NSRegularExpression(pattern: "^([a-z]{2})(?:-|[A-Z])", options: [])
            var unique: Set<String> = []
            let encoder = JSONEncoder()
            guard let jsonData = try? encoder.encode(pages),
                  let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else { return [] }
            for pageDict in jsonArray {
                guard let pageName = pageDict["page"] as? String, pageName == "government-data" else { continue }
                guard let config = pageDict["config"] as? [String: Any] else { continue }
                for (key, value) in config {
                    if let boolValue = value as? Bool, boolValue {
                        let match = regex?.firstMatch(in: key, options: [], range: NSRange(location: 0, length: key.utf16.count))
                        let code: String
                        if let match = match, let range = Range(match.range(at: 1), in: key) {
                            code = String(key[range])
                        } else {
                            code = "ng"
                        }
                        unique.insert(code.lowercased())
                    }
                }
            }
            return Array(unique)
        }()

        // Now filter countries using the computed iso codes
        let fetched = countriesLocalDatasource.getCountries()
        self.allCountries = fetched.filter { country in
            isoCodes.contains { $0.caseInsensitiveCompare(country.iso2) == .orderedSame }
        }
        self.countries = self.allCountries

        self.preference.DJCountryCode = "NG"
    }

    func filterCountries(_ text: String) {
        if text.isEmpty {
            countries = allCountries
        } else {
            countries = allCountries.filter {
                $0.countryName.insensitiveContains(text) ||
                $0.iso2.insensitiveContains(text) ||
                $0.iso3.insensitiveContains(text)
            }
        }
        viewProtocol?.refreshCountries()
    }
    
    func didChooseCountry(_ country: DJCountryDB) {
        countrySelected = true
        preference.DJCountryCode = country.iso2
        postEvent(
            request: .init(name: .countrySelected, value: country.countryName),
            showLoader: false,
            showError: false
        )
        countries = allCountries
        checkSupportedCountry(using: country.iso2)
    }
    
    func checkSupportedCountry(using iso2: String) {
        guard let preAuthCountries, preAuthCountries.isNotEmpty, preAuthCountries.contains(iso2) else {
            showCountryNotSupportedError()
            return
        }
        viewProtocol?.enableContinueButton(true)
        viewProtocol?.hideMessage()
    }
    
    private func showCountryNotSupportedError() {
        viewProtocol?.enableContinueButton(false)
        viewProtocol?.showErrorMessage(DJSDKError.countryNotSupported.uiMessage)
    }
    
    func didTapContinue() {
        if !countrySelected {
            postEvent(
                request: .init(name: .countrySelected, value: "Nigeria"),
                showLoader: false,
                showError: false
            )
        }
        postEvent(
            request: .init(name: .stepCompleted, value: "countries"),
            didSucceed: { [weak self] _ in
                self?.countrySelected = false
                runAfter {
                    self?.setNextAuthStep()
                }
            },
            didFail: { [weak self] _ in
                self?.countrySelected = false
                kprint("unable to post step_completed for countries")
            }
        )
    }
}

