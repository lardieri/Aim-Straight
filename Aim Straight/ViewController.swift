//
//  ViewController.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit
import AVFoundation
import CoreMotion
import Photos
import AsyncOperation
import InteractionQueue

fileprivate let motionUpdateInterval = TimeInterval(1.0 / 120.0)

class ViewController: UIViewController {

    // MARK: Interface Builder outlets

    @IBOutlet weak var cameraNotAvailable: UILabel!
    @IBOutlet weak var photosNotAvailable: UILabel!
    @IBOutlet weak var motionNotAvailable: UILabel!
    @IBOutlet weak var settingsPrompt: UIStackView!
    @IBOutlet weak var overlayView: OverlayView!

    // MARK: Life cycle

    override func viewDidLoad() {
        overlayView.viewModel = viewModel
        overlayView.delegate = self

        tipJarBusinessLogic.delegate = self

        addNotificationObservers()

        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        interactionQueue.onViewDidAppear()

        switch resourcesEvaluated {
            case .notStarted:
                evaluateResourceAvailability()

            case .evaluating:
                break

            case .finished:
                updateUI()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        interactionQueue.onViewWillDisappear()
        super.viewWillDisappear(animated)
    }

    // MARK: Interface Builder actions

    @IBAction func settingsTapped(_ sender: Any) {
        openSettings()
    }

    // MARK: Private methods

    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DidStopPreviewing"), object: nil, queue: nil) { _ in
            self.stopTrackingMotion()
            self.motionQueue.cancelAllOperations()

            OperationQueue.main.addOperation {
                self.overlayView.isHidden = true
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "DidStartPreviewing"), object: nil, queue: nil) { _ in
            self.startTrackingMotion()

            OperationQueue.main.addOperation {
                self.overlayView.isHidden = false
            }
        }
    }

    private func updateUI() {
        assert(resourcesEvaluated == .finished)

        if everythingAvailable {
            if presentedViewController == nil {
                presentImagePicker()
            }
        } else {
            UIView.animate(withDuration: 0.0) {
                self.cameraNotAvailable.isHidden = self.cameraAvailable
                self.photosNotAvailable.isHidden = self.photosAvailable
                self.motionNotAvailable.isHidden = self.motionAvailable
                self.settingsPrompt.isHidden = false
            }
        }
    }

    private func presentTipJar() {
        guard let imagePicker = presentedViewController as? UIImagePickerController else { return }

        let tipJarVC = storyboard!.instantiateViewController(identifier: "TipJarHostingController") as TipJarHostingController

        imagePicker.present(tipJarVC, animated: true)
    }

    private func presentThankYou() {
        let hostViewController = presentedViewController ?? self

        let title = Bundle.main.localizedString(forKey: "ThankYouTitle", value: "Thank you!", table: nil)
        let message = Bundle.main.localizedString(forKey: "ThankYouMessage", value: "I appreciate your generosity.", table: nil)

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        hostViewController.present(alert, animated: true)
    }

    private func presentImagePicker() {
        assert(presentedViewController == nil)

        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.showsCameraControls = true
        imagePicker.allowsEditing = false
        imagePicker.delegate = self

        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            imagePicker.cameraDevice = .rear
        } else {
            imagePicker.cameraDevice = .front
        }

        imagePicker.cameraOverlayView = overlayView

        present(imagePicker, animated: false, completion: nil)
    }

    private func dismissImagePicker(_ imagePicker: UIImagePickerController) {
        guard presentedViewController === imagePicker else { return }

        // When we use the built-in camera controls, we need to dismiss the picker after every picture.
        // See Apple's documentation for UIImagePickerController.
        // In order to take the next picture, we need to present a new picker.
        dismiss(animated: false) {
            OperationQueue.main.addOperation {
                self.updateUI()
            }
        }
    }

    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl) { _ in
            exit(0)
        }
    }

    private func openPhotos() {
        UIApplication.shared.open(URL(string: "photos-redirect://")!)
    }

    private func onPhotoSaved() {
        overlayView.tipJarButton.isHidden = !tipJarBusinessLogic.showTipJarAfterTakingPicture()
    }

    // MARK: Private types

    private enum ResourceEvaulationState {
        case notStarted
        case evaluating
        case finished
    }

    // MARK: Private properties

    private var everythingAvailable: Bool {
        cameraAvailable && photosAvailable && motionAvailable
    }

    private var cameraAvailable = false
    private var photosAvailable = false
    private var motionAvailable = false

    private var resourcesEvaluated = ResourceEvaulationState.notStarted
    private let interactionQueue = InteractionQueue()

    private let motionManager = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    } ()

    private let viewModel = ViewModel()

    private let tipJarBusinessLogic = TipJarBusinessLogic()

}


// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        exit(0)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompletion(_:error:context:)), nil)
        } else if let image = info[.originalImage] as? UIImage {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompletion(_:error:context:)), nil)
        }

        dismissImagePicker(picker)
    }

    @objc private func saveCompletion(_ image: UIImage, error: Error?, context: UnsafeMutableRawPointer) {
        if let error = error {
            print("Error saving photo: \(error.localizedDescription)")

            // TODO: Display error message, offer to take user to Settings.
        } else {
            print("Photo saved successfully.")

            onPhotoSaved()

            // TODO: Display thumbnail that opens the Photos app when tapped.
        }
    }

}


// MARK: - Motion processing

fileprivate extension ViewController {

    private func startTrackingMotion() {
        guard !motionManager.isDeviceMotionActive else { return }

        motionManager.deviceMotionUpdateInterval = motionUpdateInterval
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue, withHandler: processMotion(motion:error:))
    }

    private func stopTrackingMotion() {
        guard motionManager.isDeviceMotionActive else { return }

        motionManager.stopDeviceMotionUpdates()
    }

    private func processMotion(motion _: CMDeviceMotion?, error: Error?) {
        if let error = error {
            print("Motion error: \(error)")
            return
        }

        // Always read the latest value.
        motionQueue.cancelAllOperations()
        guard let motion = motionManager.deviceMotion else {
            print("Motion error: data is nil")
            return
        }

        viewModel.gravity = motion.gravity
    }

}


// MARK: - Device capabilities and permissions

fileprivate extension ViewController {

    private func evaluateResourceAvailability() {
        self.resourcesEvaluated = .evaluating

        interactionQueue.add { finished in
            self.evaluateCameraAvailability(finished: finished)
        }

        interactionQueue.add { finished in
            self.evaluatePhotoLibraryAvailability(finished: finished)
        }

        interactionQueue.add { finished in
            self.evaluateMotionAvailability(finished: finished)
        }

        interactionQueue.add { finished in
            self.resourcesEvaluated = .finished
            OperationQueue.main.addOperation {
                self.updateUI()
                finished()
            }
        }
    }

    private func evaluateCameraAvailability(finished: @escaping AsyncBlockOperation.FinishCallback) {
        guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) else {
            cameraAvailable = false
            finished()
            return
        }

        guard UIImagePickerController.isCameraDeviceAvailable(.rear) || UIImagePickerController.isCameraDeviceAvailable(.front) else {
            cameraAvailable = false
            finished()
            return
        }

        AVCaptureDevice.requestAccess(for: AVMediaType.video) { permissionGranted in
            OperationQueue.main.addOperation {
                self.cameraAvailable = permissionGranted
                finished()
            }
        }
    }

    private func evaluatePhotoLibraryAvailability(finished: @escaping AsyncBlockOperation.FinishCallback) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                OperationQueue.main.addOperation {
                    self.photosAvailable = (status == .authorized)
                    finished()
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization() { status in
                OperationQueue.main.addOperation {
                    self.photosAvailable = (status == .authorized)
                    finished()
                }
            }
        } 
    }

    private func evaluateMotionAvailability(finished: @escaping AsyncBlockOperation.FinishCallback) {
        motionAvailable = motionManager.isDeviceMotionAvailable
        finished()
    }

}


// MARK: - OverlayViewDelegate

extension ViewController: OverlayViewDelegate {

    func tipJarButtonTapped() {
        OperationQueue.main.addOperation {
            self.presentTipJar()
        }
    }

}


// MARK: - TipJarBusinessLogicDelegate

extension ViewController: TipJarBusinessLogicDelegate {

    func userMadeTipPayment() {
        OperationQueue.main.addOperation {
            self.overlayView.tipJarButton.isHidden = true
            self.presentThankYou()
        }
    }

}
