//
//  GovtIDViewController.swift
//  
//
//  Created by Isaac Iniongun on 28/10/2023.
//

import UIKit

final class GovtIDViewController: DJBaseViewController {

    private let fillFormView = FillFormView()
    private let govtIDView = DJPickerView(title: "Government Identification")
    private let govtIDNumberTextField = DJTextField(title: "")
    private let verificationMethodView = DJPickerView(title: "Verify with")
    private lazy var continueButton = DJButton(title: "Continue") { [weak self] in
        self?.didTapContinueButton()
    }
    private lazy var contentStackView = VStackView(
        subviews: [govtIDView, govtIDNumberTextField, verificationMethodView],
        spacing: 20
    )
    private lazy var contentScrollView = UIScrollView(children: [fillFormView, contentStackView])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
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
        }
        
        govtIDNumberTextField.showView(false)
    }
    
    override func addTapGestures() {
        govtIDView.valueView.didTap { [weak self] in
            self?.didTapGovtIDView()
        }
        
        verificationMethodView.valueView.didTap { [weak self] in
            self?.didTapVerificationMethodView()
        }
    }
    
    private func didTapContinueButton() {
        
    }
    
    private func didTapGovtIDView() {
        showSelectableItemsViewController(
            title: "Choose Government Identification",
            items: GovtID.allCases,
            height: 180,
            delegate: self
        )
    }
    
    private func didTapVerificationMethodView() {
        showSelectableItemsViewController(
            title: "Choose Verification Method",
            items: GovtIDVerificationMethod.allCases,
            height: 220,
            delegate: self
        )
    }

}

extension GovtIDViewController: SelectableItemsViewDelegate {
    func didChooseItem(_ item: SelectableItem) {
        if let govtID = item as? GovtID {
            govtIDView.updateValue(govtID.title)
            with(govtIDNumberTextField) {
                $0.textField.placeholder = govtID.numberTitle
                $0.title = govtID.numberTitle
                $0.showView()
            }
        }
        
        if let method = item as? GovtIDVerificationMethod {
            verificationMethodView.updateValue(method.title)
        }
    }
}
