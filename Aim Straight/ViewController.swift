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
    @IBOutlet var tiltView: TiltView!

    // MARK: Life cycle

    override func viewDidLoad() {
        tiltView.translatesAutoresizingMaskIntoConstraints = false

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

    private func updateUI() {
        assert(resourcesEvaluated == .finished)

        if everythingAvailable {
            if !motionManager.isDeviceMotionActive {
                motionManager.deviceMotionUpdateInterval = motionUpdateInterval
                motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue, withHandler: processMotion(motion:error:))
            }

            if presentedViewController == nil {
                presentImagePicker()
            }
        } else {
            cameraNotAvailable.isHidden = cameraAvailable
            photosNotAvailable.isHidden = photosAvailable
            motionNotAvailable.isHidden = motionAvailable
            settingsPrompt.isHidden = false
        }
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

        imagePicker.cameraOverlayView = tiltView

        present(imagePicker, animated: false, completion: nil)
    }

    private func dismissImagePicker() {
        guard presentedViewController is UIImagePickerController else { return }

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

        dismissImagePicker()
    }

    @objc private func saveCompletion(_ image: UIImage, error: Error?, context: UnsafeMutableRawPointer) {
        if let error = error {
            print("Error saving photo: \(error.localizedDescription)")

            // TODO: Display error message, offer to take user to Settings.
        } else {
            print("Photo saved successfully.")

            // TODO: Display thumbnail that opens the Photos app when tapped.
        }
    }

}


// MARK: - Motion processing

fileprivate extension ViewController {

    private func processMotion(motion: CMDeviceMotion?, error: Error?) {
        if let error = error {
            print("Motion error: \(error)")
            return
        }

        guard let motion = motion else {
            print("Motion error: data is nil")
            return
        }

        let gravity = motion.gravity

        tiltView.normalizedRoll = gravity.roll
        tiltView.normalizedPitch = gravity.pitch
    }

    private func printGravity(_ gravity: CMAcceleration) {
        func format(_ d: Double) -> String {
            return String(format: "%+.2f", d)
        }

        let x = format(gravity.x)
        let y = format(gravity.y)
        let z = format(gravity.z)
        let magnitude = format(gravity.magnitude)
        let pitch = format(gravity.pitch)
        let roll = format(gravity.roll)

        print("Gravity vector: (x: \(x), y: \(y), z: \(z)  magnitude: \(magnitude)  dominant: \(gravity.dominantAxis)  pitch: \(pitch)  roll: \(roll)")
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
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            OperationQueue.main.addOperation {
                self.photosAvailable = (status == .authorized)
                finished()
            }
        }
    }

    private func evaluateMotionAvailability(finished: @escaping AsyncBlockOperation.FinishCallback) {
        motionAvailable = motionManager.isDeviceMotionAvailable
        finished()
    }

}
