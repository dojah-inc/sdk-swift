//
//  SelfieVideoKYCViewController.swift
//
//
//  Created by Isaac Iniongun on 31/10/2023.
//

import UIKit
import AVFoundation
import ImageIO
import Vision

final class SelfieVideoKYCViewController: DJBaseViewController {

    private let viewModel: SelfieVideoKYCViewModel
    //private var viewState = SelfieVideoKYCViewState.capture
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let faceDetectionQueue = DispatchQueue(label: "com.dojah.selfie-video-kyc.face-detection")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var countdownTimer: Timer?
    private var countdownValue = 0
    private var currentFaceGuidance: FaceCaptureGuidance?
    private var didAutoCaptureSelfie = false
    private var isFaceDetectionActive = false

    init(viewModel: SelfieVideoKYCViewModel = SelfieVideoKYCViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        kviewModel = viewModel
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var topHintView = PillTextView(
        text: viewState.hintText,
        textColor: .white,
        bgColor: .black
    )
    private lazy var cameraHintView = PillTextView(
        text: "Loading camera...",
        textColor: .white,
        bgColor: .black
    )
    private let cameraPreviewWidth: CGFloat = 285
    private let cameraPreviewHeight: CGFloat = 360
    private lazy var selfiePreviewWidth = cameraPreviewWidth * 0.8
    private lazy var selfiePreviewHeight = cameraPreviewHeight * 0.8
    private lazy var cameraGuideWidth = cameraPreviewWidth * 0.84
    private lazy var cameraGuideHeight = cameraGuideWidth * (268.0 / 216.0)
    private lazy var cameraContainerView = UIView(
        height: cameraPreviewHeight,
        width: cameraPreviewWidth,
        backgroundColor: .clear,
        radius: cameraPreviewWidth / 2,
        clipsToBounds: false
    )
    private lazy var cameraView = UIView(
        height: cameraPreviewHeight,
        width: cameraPreviewWidth,
        backgroundColor: .djBorder.withAlphaComponent(0.3),
        radius: cameraPreviewWidth / 2,
        clipsToBounds: true
    )
    private lazy var cameraBorderView = UIView(
        height: cameraPreviewHeight,
        width: cameraPreviewWidth,
        backgroundColor: .clear,
        clipsToBounds: false
    )
    private lazy var cameraBorderStackView = cameraBorderView.withHStackCentering()
    private lazy var selfieImageView = UIImageView(
        image: .res("femaleSelfie"),
        contentMode: .scaleAspectFill,
        height: selfiePreviewHeight,
        width: selfiePreviewWidth,
        cornerRadius: selfiePreviewWidth / 2
    )
    private lazy var cameraGuideImageView = UIImageView(
        image: .res(FaceCaptureGuidance.centerFace.assetName),
        contentMode: .scaleAspectFit,
        height: cameraGuideHeight,
        width: cameraGuideWidth
    )
    private lazy var countdownLabel = UILabel(
        text: "",
        font: .bold(76),
        numberOfLines: 1,
        color: .systemGreen,
        alignment: .center
    )
    // private let bottomHintView = PillIconTextView(
    //     text: "Please make sure you are in a well lit environment",
    //     font: .light(13),
    //     icon: .res("redInfoCircle"),
    //     iconSize: 18,
    //     textColor: .djRed,
    //     bgColor: .djLightRed,
    //     cornerRadius: 15
    // )
    //private lazy var bottomHintStackView = bottomHintView.withHStackCentering()
    private let disclaimerItemsView = DisclaimerItemsView(items: DJConstants.selfieCaptureDisclaimerItems)
    private lazy var primaryButton = DJButton(
        title: "\(viewModel.verificationMethod.kycText)",
        isEnabled: false
    ) { [weak self] in
        self?.didTapPrimaryButton()
    }
    private lazy var secondaryButton = DJButton(
        title: "Retake",
        font: .medium(15),
        backgroundColor: .primaryGrey,
        textColor: .aLabel,
        borderWidth: 1,
        borderColor: .djBorder
    ) { [weak self] in
        self?.didTapSecondaryButton()
    }
    private lazy var selfieImageStackView = selfieImageView.withHStackCentering()
    private lazy var contentStackView = VStackView(
        subviews: [topHintView.withHStackCentering(), cameraBorderStackView,
                   disclaimerItemsView, secondaryButton, primaryButton],
        spacing: 40
    )
    private lazy var contentScrollView = UIScrollView(children: [contentStackView])
    private var selfieImageBlurEffectView: UIVisualEffectView?
    private var viewState: SelfieVideoKYCViewState {
        viewModel.viewState
    }
    deinit {
        countdownTimer?.invalidate()
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        showNavBar(false)
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        runAfter { [weak self] in
            self?.setBorders()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetFaceCaptureCountdown()
        startCaptureSession(false)
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
                padding: .kinit(top: 60, bottom: 20)
            )
            contentStackView.setCustomSpacing(15, after: selfieImageStackView)
            contentStackView.setCustomSpacing(15, after: secondaryButton)
            contentStackView.setCustomSpacing(20, after: disclaimerItemsView)
        }

        [disclaimerItemsView, secondaryButton, primaryButton].showViews(false)

        attachmentManager.imagePickedHandler = { [weak self] uiimage, imageURL, sourceType in
            self?.didPickImage(uiimage, at: imageURL, using: sourceType)
        }

        cameraBorderView.addSubviews(cameraContainerView, cameraGuideImageView, countdownLabel)
        cameraContainerView.centerInSuperview()
        cameraGuideImageView.centerInSuperview()
        cameraContainerView.addSubviews(selfieImageView, cameraView, cameraHintView)
        [cameraView, selfieImageView].centerInSuperview()
        cameraHintView.centerXInSuperview()
        cameraHintView.anchor(bottom: cameraContainerView.bottomAnchor, padding: .kinit(bottom: 18))
        cameraHintView.leadingAnchor.constraint(greaterThanOrEqualTo: cameraContainerView.leadingAnchor, constant: 12).isActive = true
        cameraHintView.trailingAnchor.constraint(lessThanOrEqualTo: cameraContainerView.trailingAnchor, constant: -12).isActive = true
        countdownLabel.centerInSuperview(size: .init(width: 150, height: 110))
        selfieImageView.showView(false)
        countdownLabel.showView(false)
        cameraGuideImageView.showView()

        runAfter { [weak self] in
            self?.setupCameraView()
        }
    }

    private func setupCameraView() {
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            kprint("Front camera not available.")
            cameraHintView.text = "Camera loading error."
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)

            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                captureSession.beginConfiguration()
                captureSession.sessionPreset = .high
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
                setupFaceDetectionVideoOutput()
                captureSession.commitConfiguration()

                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = .resizeAspectFill
                guard let previewLayer else { return }
                primaryButton.enable(!isFaceDetectionActive)
                cameraHintView.showView(false)
                cameraView.clearBackground()
                previewLayer.frame = cameraView.layer.bounds
                cameraView.layer.insertSublayer(previewLayer, at: 0)
                updateCameraConnectionOrientation()

                startCaptureSession()
            }
        } catch {
            kprint("Error setting up camera input: \(error.localizedDescription)")
        }
    }

    private func setupFaceDetectionVideoOutput() {
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: faceDetectionQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            isFaceDetectionActive = true
        } else {
            isFaceDetectionActive = false
        }
    }

    private func updateCameraConnectionOrientation() {
        configureCameraConnection(previewLayer?.connection)
        configureCameraConnection(videoOutput.connection(with: .video))
    }

    private func configureCameraConnection(_ connection: AVCaptureConnection?) {
        guard let connection else { return }
        connection.videoOrientation = .portrait
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
    }

    private func setBorders() {
        previewLayer?.frame = cameraView.layer.bounds
        applyOvalMask(to: cameraView)
        applyOvalMask(to: selfieImageView)
        cameraGuideImageView.image = .res(currentFaceGuidance?.assetName ?? FaceCaptureGuidance.centerFace.assetName)
    }

    private func applyOvalMask(to view: UIView) {
        guard view.bounds != .zero else { return }
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(ovalIn: view.bounds).cgPath
        view.layer.mask = maskLayer
    }

    private func didPickImage(
        _ uiimage: UIImage,
        at imageURL: URL?,
        using sourceType: UIImagePickerController.SourceType
    ) {
        resetFaceCaptureCountdown()
        selfieImageView.image = uiimage
        [disclaimerItemsView, secondaryButton].showViews()
        [topHintView].showViews(false)
        updateViewState()
    }

    private func updateViewState() {
        switch viewState {
        case .capture:
            viewModel.viewState = .previewSelfie
        case .previewSelfie:
            viewModel.viewState = .capture
        case .record:
            viewModel.viewState = .previewSelfieVideo
        case .previewSelfieVideo:
            viewModel.viewState = .record
        }
        updateUIState()
    }

    private func updateUIState() {
        primaryButton.title = viewState.primaryButtonTitle
        topHintView.text = viewState.hintText

        switch viewState {
        case .capture:
            didAutoCaptureSelfie = false
            currentFaceGuidance = nil
            resetFaceCaptureCountdown()
            cameraView.backgroundColor = .djBorder.withAlphaComponent(0.3)
            topHintView.showView()
            [cameraView].showViews()
            cameraHintView.showView(false)
            [disclaimerItemsView, secondaryButton, selfieImageView].showViews(false)
            cameraGuideImageView.showView()
            primaryButton.showView(false)
            primaryButton.enable(!isFaceDetectionActive)
            startCaptureSession()
            if isFaceDetectionActive {
                applyFaceCaptureGuidance(.centerFace)
            }
        case .previewSelfie:
            resetFaceCaptureCountdown()
            startCaptureSession(false)
            [cameraHintView, cameraView, cameraGuideImageView].showViews(false)
            [disclaimerItemsView, secondaryButton, selfieImageView].showViews()
            primaryButton.showView()
            primaryButton.enable()
        case .record:
            resetFaceCaptureCountdown()
            cameraView.backgroundColor = .djBorder.withAlphaComponent(0.3)
            [cameraHintView, cameraView].showViews()
            [disclaimerItemsView, secondaryButton, selfieImageView].showViews(false)
            primaryButton.showView(false)
            //startCaptureSession() //TODO: do video stuff
        case .previewSelfieVideo:
            resetFaceCaptureCountdown()
            //startCaptureSession(false) //TODO: do video stuff
            [cameraHintView, cameraView, cameraGuideImageView].showViews(false)
            [disclaimerItemsView, secondaryButton, selfieImageView].showViews()
            primaryButton.showView()
        }
    }

    private func didTapPrimaryButton() {
        switch viewState {
        case .capture:
            capturePhoto()
        case .previewSelfie:
            viewModel.performImageCheck()
        case .record:
            break //TODO: do video recording
        case .previewSelfieVideo:
            break //TODO: do video analysis
        }
    }

    private func didTapSecondaryButton() {
        didAutoCaptureSelfie = false
        currentFaceGuidance = nil
        resetFaceCaptureCountdown()
        updateViewState()
    }

    private func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = .off
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }

    private func startCaptureSession(_ start: Bool = true) {
        if start {
            cameraHintView.showView(false)
        } else {
            cameraHintView.showView()
        }
        runOnBackgroundThread { [weak self] in
            start ? self?.captureSession.startRunning() : self?.captureSession.stopRunning()
        }
    }

    private func applyFaceCaptureGuidance(_ guidance: FaceCaptureGuidance) {
        guard viewState == .capture, !didAutoCaptureSelfie else { return }

        if guidance == .ready {
            startFaceCaptureCountdown()
        } else {
            resetFaceCaptureCountdown()
        }

        guard guidance != currentFaceGuidance else { return }
        currentFaceGuidance = guidance
        topHintView.text = guidance.message
        topHintView.showView()
        cameraGuideImageView.image = .res(guidance.assetName)
        cameraGuideImageView.showView()
        cameraHintView.showView(false)
    }

    private func startFaceCaptureCountdown() {
        guard countdownTimer == nil else { return }
        countdownValue = 1
        cameraHintView.showView(false)
        countdownLabel.text = "\(countdownValue)"
        countdownLabel.showView()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            self.countdownValue += 1
            if self.countdownValue <= 3 {
                self.countdownLabel.text = "\(self.countdownValue)"
                return
            }
            timer.invalidate()
            self.countdownTimer = nil
            self.didAutoCaptureSelfie = true
            self.countdownLabel.showView(false)
            self.capturePhoto()
        }
    }

    private func resetFaceCaptureCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownValue = 0
        countdownLabel.text = ""
        countdownLabel.showView(false)
        if viewState == .capture {
            cameraGuideImageView.showView()
        }
    }

    override func showLoader(_ show: Bool) {
        [primaryButton, secondaryButton].enable(!show)
        with(cameraHintView) {
            $0.showView(show)
            $0.backgroundColor = show ? .primary : .black
            $0.textLabel.text = "Proccessing..."
        }
        if show {
            selfieImageBlurEffectView = selfieImageView.applyBlurEffect(alpha: 0.8)
        } else {
            selfieImageBlurEffectView?.removeFromSuperview()
            selfieImageBlurEffectView = nil
        }
    }

}

private enum FaceCaptureGuidance: Equatable {
    case centerFace
    case multipleFaces
    case moveBack
    case moveCloser
    case poorLighting
    case highLighting
    case ready

    var message: String {
        switch self {
        case .centerFace:
            return "Center your face in the oval"
        case .ready: return "Capturing..."
        case .multipleFaces:
            return "Multiple faces detected"
        case .moveBack:
            return "Move back a little."
        case .moveCloser:
            return "Move closer to the camera."
        case .poorLighting:
            return "Poor lighting. Move to a well-lit environment"
        case .highLighting:
            return "High lighting. Move to a balance-lit environment"
        }
    }

    var assetName: String {
        self == .ready ? "ic_camera_face_detected" : "ic_capture_ready"
    }
}

private enum FaceCaptureThreshold {
    static let minimumFaceSizeRatio: CGFloat = 0.30
    static let maximumFaceSizeRatio: CGFloat = 0.72
    static let maximumCenterOffsetX: CGFloat = 0.10
    static let maximumCenterOffsetY: CGFloat = 0.12
}

extension SelfieVideoKYCViewController: SelfieVideoKYCViewProtocol {
    func showSelfieImageError(message: String) {
        runOnMainThread { [weak self] in
            guard let self else { return }
            with(self.cameraHintView) {
                $0.showView()
                $0.backgroundColor = .red
                $0.textLabel.text = message
            }
            [self.primaryButton, self.secondaryButton].enable()

            runAfter(2) {
                self.showLoader(false)
            }
        }
    }
}

extension SelfieVideoKYCViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard viewState == .capture, isFaceDetectionActive, !didAutoCaptureSelfie else { return }
        // Apple Vision avoids ML Kit Clearcut/SRL failures in Flutter/RN host apps.
        processFaceFrameWithVision(sampleBuffer)
    }

    private func processFaceFrameWithVision(_ sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(
            cvPixelBuffer: imageBuffer,
            orientation: cgImagePropertyOrientation(
                deviceOrientation: UIDevice.current.orientation,
                cameraPosition: .front
            ),
            options: [:]
        )

        do {
            try handler.perform([request])
            let guidance = faceCaptureGuidance(
                for: request.results ?? [],
                sampleBuffer: sampleBuffer
            )
            runOnMainThread { [weak self] in
                self?.applyFaceCaptureGuidance(guidance)
            }
        } catch {
            kprint("Error detecting face with Vision: \(error.localizedDescription)")
        }
    }

    private func faceCaptureGuidance(
        for faces: [VNFaceObservation],
        sampleBuffer: CMSampleBuffer
    ) -> FaceCaptureGuidance {
        if let brightnessValue = brightnessValue(from: sampleBuffer) {
            if brightnessValue < -1.2 {
                return .poorLighting
            }
            if brightnessValue > 3.8 {
                return .highLighting
            }
        }

        guard !faces.isEmpty else {
            return .centerFace
        }
        guard faces.count == 1, let face = faces.first else {
            return .multipleFaces
        }

        let boundingBox = face.boundingBox
        let largestFaceSideRatio = max(boundingBox.width, boundingBox.height)
        let smallestFaceSideRatio = min(boundingBox.width, boundingBox.height)

        if largestFaceSideRatio > FaceCaptureThreshold.maximumFaceSizeRatio {
            return .moveBack
        }
        if smallestFaceSideRatio < FaceCaptureThreshold.minimumFaceSizeRatio {
            return .moveCloser
        }

        let centerOffsetX = abs(boundingBox.midX - 0.5)
        let centerOffsetY = abs(boundingBox.midY - 0.5)
        if centerOffsetX > FaceCaptureThreshold.maximumCenterOffsetX ||
            centerOffsetY > FaceCaptureThreshold.maximumCenterOffsetY {
            return .centerFace
        }

        return .ready
    }

    private func brightnessValue(from sampleBuffer: CMSampleBuffer) -> Double? {
        guard
            let metadata = CMGetAttachment(
                sampleBuffer,
                key: kCGImagePropertyExifDictionary,
                attachmentModeOut: nil
            ) as? [String: Any],
            let brightnessValue = metadata[kCGImagePropertyExifBrightnessValue as String] as? NSNumber
        else {
            return nil
        }
        return brightnessValue.doubleValue
    }

    private func cgImagePropertyOrientation(
        deviceOrientation: UIDeviceOrientation,
        cameraPosition: AVCaptureDevice.Position
    ) -> CGImagePropertyOrientation {
        switch deviceOrientation {
        case .portrait:
            return cameraPosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return cameraPosition == .front ? .leftMirrored : .right
        @unknown default:
            return cameraPosition == .front ? .leftMirrored : .right
        }
    }
}

extension SelfieVideoKYCViewController: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let uiImage = UIImage(data: imageData) {
            viewModel.imageData = imageData
            didCaptureImage(uiImage)
        } else {
            kprint("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    private func didCaptureImage(_ uiImage: UIImage) {
        runOnMainThread { [weak self] in
            self?.updateViewState()
            self?.selfieImageView.image = uiImage
        }
    }
}
