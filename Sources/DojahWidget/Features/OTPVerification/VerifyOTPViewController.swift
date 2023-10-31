//
//  VerifyOTPViewController.swift
//  
//
//  Created by Isaac Iniongun on 31/10/2023.
//

import UIKit

final class VerifyOTPViewController: DJBaseViewController {

    private let viewModel: OTPVerificationViewModel
    
    init(viewModel: OTPVerificationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var attrInfo = AttributedStringBuilder()
        .text("Enter the code sent to ", attributes: [.textColor(.aLabel), .font(.regular(15))])
        .text(viewModel.verificationInfo, attributes: [.textColor(.primary), .font(.regular(15))])
        .attributedString
    private lazy var attrLabel = UILabel(attributedText: attrInfo, alignment: .center)
    private lazy var otpView: SVPinView = {
        with(SVPinView()) {
            $0.pinLength = 4
            $0.secureCharacter = "\u{25CF}"
            $0.interSpace = 15
            $0.textColor = .aLabel
            $0.shouldSecureText = true
            $0.style = .box

            $0.borderLineColor = .djBorder
            $0.activeBorderLineColor = .primary
            $0.borderLineThickness = 1
            $0.activeBorderLineThickness = 1
            $0.fieldCornerRadius = 5
            $0.fieldBackgroundColor = .primaryGrey
            $0.activeFieldBackgroundColor = .primaryGrey
            $0.activeFieldCornerRadius = 5

            $0.font = .bold(25)
            $0.keyboardType = .phonePad
            $0.keyboardAppearance = .default
            $0.pinInputAccessoryView = UIView()
            $0.placeholder = "\u{25CF}\u{25CF}\u{25CF}\u{25CF}"
            $0.becomeFirstResponderAtIndex = 0
            $0.isContentTypeOneTimeCode = true
            
            $0.didFinishCallback = handleOTPCompleted(_:)
        }
    }()
    private lazy var resendCodeButton = DJButton(
        title: "Resend code",
        font: .medium(15),
        backgroundColor: .clear,
        textColor: .primary,
        height: nil
    ) { [weak self] in
        
    }
    private lazy var continueButton = DJButton(title: "Continue", isEnabled: false) { [weak self] in
        self?.didTapContinueButton()
    }
    private lazy var contentStackView = VStackView(
        subviews: [attrLabel, otpView, resendCodeButton, continueButton],
        spacing: 20
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        with(contentStackView) {
            addSubview($0)
            $0.anchor(
                top: navView.bottomAnchor,
                leading: safeAreaLeadingAnchor,
                trailing: safeAreaTrailingAnchor,
                padding: .kinit(topBottom: 50, leftRight: 20)
            )
        }
    }
    
    private func handleOTPCompleted(_ otp: String) {
        continueButton.enable(otp.countEquals(4))
    }
    
    private func didTapContinueButton() {
        
    }

}
