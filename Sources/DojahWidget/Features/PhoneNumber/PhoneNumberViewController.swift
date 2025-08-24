//
//  PhoneNumberViewController.swift
//
//
//  Created by Isaac Iniongun on 01/05/2024.
//

import UIKit

final class PhoneNumberViewController: DJBaseViewController {

    private let viewModel: PhoneNumberViewModel

    init(viewModel: PhoneNumberViewModel = PhoneNumberViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        kviewModel = viewModel
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let phoneNumberTextField = DJPhoneNumberTextField()

    private lazy var verificationMethodView = DJPickerView(
        title: "Verify with",
        items: viewModel.verificationMethods,
        itemSelectionHandler: { [weak self] _, index in
            self?.viewModel.didChooseVerificationMethod(index: index)
        }
    )

    private lazy var continueButton = DJButton(
        title: "Continue",
        isEnabled: false
    ) { [weak self] in
        self?.viewModel.didTapContinue()
    }

    private lazy var phoneStackView = VStackView(
        subviews: [phoneNumberTextField, verificationMethodView],
        spacing: 16
    )

    private lazy var contentStackView = VStackView(
        subviews: [phoneStackView, continueButton],
        spacing: 50
    )
    private lazy var contentScrollView = UIScrollView(children: [
        contentStackView
    ])

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        viewModel.viewProtocol = self
        with(contentScrollView) {
            addSubview($0)

            $0.anchor(
                top: navView.bottomAnchor,
                leading: safeAreaLeadingAnchor,
                bottom: poweredView.topAnchor,
                trailing: safeAreaTrailingAnchor,
                padding: .kinit(leftRight: 20)
            )

            contentStackView.anchor(
                top: $0.ktopAnchor,
                leading: $0.kleadingAnchor,
                bottom: $0.kbottomAnchor,
                trailing: $0.ktrailingAnchor,
                padding: .kinit(top: 50, bottom: 20)
            )
        }

        configurePhoneNumberTextfield()
    }

    private func configurePhoneNumberTextfield() {
        if viewModel.verificationMethods.countEquals(1) {
            viewModel.didChooseVerificationMethod(index: 0)
            verificationMethodView.selectItem(
                item: viewModel.verificationMethods[0],
                index: 0
            )
        }

        with(phoneNumberTextField) {
            $0.updateDatasource(viewModel.countries.emoticonPhoneCodes)

            $0.didChooseCountry = { [weak self] index in
                self?.viewModel.didChooseCountry(index: index)
            }

            $0.textDidChange = { [weak self] number in
                self?.viewModel.numberDidChange(number)
            }
        }
    }

}

extension PhoneNumberViewController: PhoneNumberViewProtocol {
    func updateVerificationMethod(method: String, index: Int) {
        verificationMethodView.selectItem(item: method, index: index)
    }

    func showErrorMessage(_ message: String) {
        navView.showErrorMessage(message)
    }

    func hideMessage() {
        navView.hideMessage()
    }

    func updateCountryDetails(phoneCode: String, flag: UIImage) {
        phoneNumberTextField.updateCountryDetails(
            phoneCode: phoneCode,
            flag: flag
        )
    }

    func enableContinueButton(_ enable: Bool) {
        continueButton.enable(enable)
    }

    func showVerifyController() {
        showOtpVerification()
    }
}
