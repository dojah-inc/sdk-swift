//
//  GovernmentDataViewController.swift
//
//
//  Created by Isaac Iniongun on 28/10/2023.
//

import UIKit

final class GovernmentDataViewController: DJBaseViewController {
    
    private let viewModel: DJGovernmentDataViewModel
    
    init(viewModel: DJGovernmentDataViewModel = DJGovernmentDataViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        kviewModel = viewModel
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let fillFormView = IconInfoView(text: "Fill the form as it appears on your valid ID")
    private lazy var govtIDView = DJPickerView(
        title: "Government Identification",
        items: viewModel.governmentIDs.names,
        itemSelectionHandler: { [weak self] _, index in
            self?.viewModel.didChooseGovernmentData(at: index, type: .id)
        }
    )
    private let govtIDNumberTextField = DJTextField(title: "Govt. ID Number")
    private lazy var verificationMethodView = DJPickerView(
        title: "Verify with",
        items: viewModel.governmentIDVerificationMethods.names,
        itemSelectionHandler: { [weak self] _, index in
            self?.viewModel.didChooseGovernmentData(at: index, type: .verificationMethod)
        }
    )
    private lazy var continueButton = DJButton(title: "Continue") { [weak self] in
        self?.viewModel.didTapContinue()
    }
    private lazy var contentStackView = VStackView(
        subviews: [govtIDView, govtIDNumberTextField, verificationMethodView, continueButton],
        spacing: 20
    )
    private lazy var contentScrollView = UIScrollView(children: [fillFormView, contentStackView])
    private var govtID: GovtID?
    private var govtIDVerificationMethod: GovtIDVerificationMethod?
    
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
            
            fillFormView.centerXInSuperview()
            fillFormView.anchor(
                top: $0.ktopAnchor,
                padding: .kinit(top: 40)
            )
            
            contentStackView.anchor(
                top: fillFormView.bottomAnchor,
                leading: $0.kleadingAnchor,
                bottom: $0.kbottomAnchor,
                trailing: $0.ktrailingAnchor,
                padding: .kinit(top: 50, bottom: 20)
            )
            contentStackView.setCustomSpacing(40, after: verificationMethodView)
        }
        
        govtIDNumberTextField.showView(false)
        govtIDNumberTextField.textDidChange = { [weak self] text in
            self?.viewModel.idNumber = text
        }
    }
    
}

extension GovernmentDataViewController: GovernmentDataViewProtocol {
    func showGovtIDNumberTextField() {
        guard let governmentID = viewModel.selectedGovernmentID else { return }
        with(govtIDNumberTextField) {
            $0.textField.placeholder = governmentID.placeholder
            $0.title = governmentID.name ?? "ID Number"
            $0.textField.keyboardType = governmentID.inputType?.keyboardType ?? .default
            $0.maxLength = governmentID.maxLength?.int
            $0.showView()
        }
    }
    
    func errorAction() {
        kpop()
    }
    
    func updateVerificationMethods() {
        with(verificationMethodView) {
            $0.selectionItems = viewModel.governmentIDVerificationMethods.names
            $0.updateValue("")
        }
    }
}
