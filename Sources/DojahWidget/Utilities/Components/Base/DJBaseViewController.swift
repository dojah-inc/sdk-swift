//
//  DJBaseViewController.swift
//
//
//  Created by Isaac Iniongun on 27/10/2023.
//

import CoreLocation
import UIKit

public class DJBaseViewController: UIViewController {
    let navView = DJNavBarView()
    let poweredView = DJPoweredView()
    var kviewModel: BaseViewModel? {
        didSet {
            bindViewModel()
        }
    }
    private lazy var loaderViewController: LoaderViewController = {
        let controller = LoaderViewController()
        controller.modalPresentationStyle = .overCurrentContext
        return controller
    }()
    let attachmentManager = AttachmentManager.shared
    let locationManager = LocationManager.shared

    public override func viewDidLoad() {
        super.viewDidLoad()
        setUserInterfaceStyle()
        backgroundColor = .aSystemBackground
        setupNavView()
        setupPoweredView()
        addTapGestures()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.resignFirstResponder()
        //        if preference.DJAuthStep.name != .email {
        //            kviewModel?.setNextAuthStep(step: -1)
        //        }
        print(
            "current page is \(String(describing: preference.DJAuthStep.name))"
        )
        //Is popped to the preview screen in the stack
        if self.isMovingFromParent == true {
            print("View controller was popped:DJBaseViewController")
        } else {
            print("New view controller was pushed:DJBaseViewController")
        }
    }

    private func setupNavView() {
        with(navView) {
            addSubview($0)
            $0.delegate = self
            $0.anchor(
                top: safeAreaTopAnchor,
                leading: safeAreaLeadingAnchor,
                trailing: safeAreaTrailingAnchor,
                padding: .kinit(top: 10, left: 5, right: 16)
            )
        }
    }

    private func setupPoweredView() {
        with(poweredView) {
            addSubview($0)
            $0.centerXInSuperview()
            $0.anchor(
                bottom: safeAreaBottomAnchor,
                padding: .kinit(bottom: 8)
            )
        }
    }

    func addTapGestures() {}

    func bindViewModel() {
        kviewModel?.showLoader = { [weak self] show in
            runOnMainThread {
                self?.showLoader(show)
            }
        }

        kviewModel?.showMessage = { [weak self] config in
            self?.showMessage(config: config)
        }

        kviewModel?.showNextPage = { [weak self] in
            runOnMainThread {
                self?.showNextPage()
            }
        }

        kviewModel?.errorDoneAction = { [weak self] in
            runOnMainThread {
                self?.kpop()
            }
        }

        kviewModel?.showGovtIDPage = { [weak self] govtID in
            runOnMainThread {
                self?.showGovernmentIDViewController(govtID)
            }
        }

        kviewModel?.verificationDoneAction = { [weak self] in
            runOnMainThread {
                self?.kpopToRoot()
            }
        }
    }

    func showLoader(_ show: Bool) {
        if show {
            kpresent(vc: loaderViewController)
        } else {
            loaderViewController.kdismiss()
        }
    }

    func showMessage(config: FeedbackConfig) {
        runOnMainThread { [weak self] in
            self?.showFeedbackController(config: config)
        }
    }

    func showNextPage() {
        guard let kviewModel else { return }
        let pageName = kviewModel.preference.DJAuthStep.name
        switch pageName {
        case .countries:
            if kviewModel.preference.DJCanSeeCountryPage {
                let viewController = CountryPickerViewController()
                kpush(viewController)
            } else {
                kviewModel.setNextAuthStep()
            }
        case .userData:
            let controller = UserDataViewController()
            kpush(controller)
        case .phoneNumber:
            let controller = PhoneNumberViewController()
            kpush(controller)
        case .address:
            didChooseAddressVerification()
        case .email:
            let controller = EmailViewController()
            kpush(controller)
        case .governmentData:
            let controller = GovernmentDataViewController()
            kpush(controller)
        case .governmentDataVerification:
            guard
                let verificationMode = kviewModel.preference
                    .DJSelectedGovernmentIDVerificationMethod?
                    .verificationModeParam
            else { return }
        
            if verificationMode == "OTP" || verificationMode == "Whatsapp" {
                showOtpVerification()
            } else {
                didChooseLiveness()
            }
        case .businessData:
            let controller = BusinessDataViewController()
            kpush(controller)
        case .selfie:
            if preference.DJAuthStep.config?.version == 3 {
                didChooseLiveness()
            } else {
                didChooseLiveness(
                    verificationMethod: .selfieVideo,
                    viewState: .record
                )
            }
        case .id, .businessID, .additionalDocument:
            let controller = GovtIDCaptureViewController()
            kpush(controller)
        case .index:
            break
        case .idOptions:
            let controller = GovtIDOptionsViewController()
            kpush(controller)
        case .signature:
            let controller = SignatureViewController()
            kpush(controller)
        case .none:
            break
        }
    }

    func showOtpVerification() {
        let controller = VerifyOTPViewController()
        kpush(controller)
    }

    private func didChooseLiveness(
        verificationMethod: GovtIDVerificationMethod = .selfie,
        viewState: SelfieVideoKYCViewState = .capture
    ) {
        if attachmentManager.hasCameraPermission {
            showSelfieVideoController(
                verificationMethod: verificationMethod,
                viewState: viewState
            )
        } else {
            let controller = PermissionViewController(permissionType: .camera) {
                [weak self] in
                self?.attachmentManager.requestCameraPermission(success: {
                    [weak self] in
                    self?.showSelfieVideoController(
                        verificationMethod: verificationMethod,
                        viewState: viewState
                    )
                })
            }
            controller.modalPresentationStyle = .overCurrentContext
            kpresent(vc: controller)
        }
    }

    private func showSelfieVideoController(
        verificationMethod: GovtIDVerificationMethod = .selfie,
        viewState: SelfieVideoKYCViewState = .capture
    ) {
        let viewModel = SelfieVideoKYCViewModel(
            verificationMethod: verificationMethod,
            viewState: viewState
        )
        let controller = SelfieVideoKYCViewController(viewModel: viewModel)
        kpush(controller)
    }

    private func didChooseAddressVerification() {
        locationManager.didChangeAuthorization = { [weak self] status in
            self?.didChangeLocationAuthorization(status)
        }

        let isManualLocationSet =
            preference.DJExtraUserData?.location?.isParamSet() == true
        if locationManager.hasLocationPermission || isManualLocationSet {
            showAddressVerificationController()
        } else {
            let controller = PermissionViewController(permissionType: .location)
            { [weak self] in
                self?.locationManager.requestAuthorization()
            }
            controller.modalPresentationStyle = .overCurrentContext
            kpresent(vc: controller)
        }
    }

    private func didChangeLocationAuthorization(_ status: CLAuthorizationStatus)
    {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            showAddressVerificationController()
        case .notDetermined, .restricted, .denied:
            showToast(
                message:
                    "Location services are required for address verification",
                type: .error
            )
        @unknown default:
            showToast(
                message:
                    "Location services are required for address verification",
                type: .error
            )
        }
    }

    private func showAddressVerificationController() {
        let controller = AddressVerificationViewController()
        kpush(controller)
    }

    func didTapNavBackButton() {
        if preference.DJAuthStep.name != .email {
            kviewModel?.setNextAuthStep(step: -1)
        }
        kpop()
    }

    func didTapNavCloseButton() {
        self.navigationController?.popToRootViewController(animated: false)
        //        if preference.DJAuthStep.name != .email {
        //            kviewModel?.setNextAuthStep(step: -1)
        //        }
        //        kpop()
    }

    private func showGovernmentIDViewController(_ govtID: DJGovernmentID) {
        let viewModel = GovtIDCaptureViewModel(selectedID: govtID)
        let controller = GovtIDCaptureViewController(viewModel: viewModel)
        kpush(controller)
    }

}

extension DJBaseViewController: DJNavBarViewDelegate {
    func didTapBack() {
        didTapNavBackButton()
    }

    func didDismiss() {
        didTapNavCloseButton()
    }
}
