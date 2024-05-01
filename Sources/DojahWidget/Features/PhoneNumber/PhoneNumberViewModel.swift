//
//  PhoneNumberViewModel.swift
//
//
//  Created by Isaac Iniongun on 01/05/2024.
//

import Foundation

final class PhoneNumberViewModel: BaseViewModel {
    weak var viewProtocol: PhoneNumberViewProtocol?
    private let countriesLocalDatasource: CountriesLocalDatasourceProtocol
    var countries = [DJCountryDB]()
    private var selectedCountry: DJCountryDB?
    
    init(countriesLocalDatasource: CountriesLocalDatasourceProtocol = CountriesLocalDatasource()) {
        self.countriesLocalDatasource = countriesLocalDatasource
        countries = countriesLocalDatasource.getCountries().sorted { $0.phoneCode < $1.phoneCode }
        super.init()
    }
    
    func didChooseCountry(index: Int) {
        guard index >= 0, index < countries.count else { return }
        selectedCountry = countries[index]
        guard let selectedCountry else { return }
        viewProtocol?.updateCountryDetails(
            phoneCode: selectedCountry.phoneCode,
            flag: selectedCountry.flag
        )
    }
}
