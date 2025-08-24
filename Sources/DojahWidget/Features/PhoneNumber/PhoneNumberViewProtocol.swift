//
//  PhoneNumberViewProtocol.swift
//
//
//  Created by Isaac Iniongun on 01/05/2024.
//

import Foundation
import UIKit

protocol PhoneNumberViewProtocol: BaseViewProtocol {
    func updateCountryDetails(phoneCode: String, flag: UIImage)
    func enableContinueButton(_ enable: Bool)
    func showVerifyController()
    func updateVerificationMethod(method: String, index: Int)
}
