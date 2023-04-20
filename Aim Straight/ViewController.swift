//
//  ViewController.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit
import AVFoundation
import CoreMotion

class ViewController: UIViewController {

    // MARK: Interface Builder outlets

    @IBOutlet weak var cameraNotAvailable: UILabel!
    @IBOutlet weak var photosNotAvailable: UILabel!
    @IBOutlet weak var motionNotAvailable: UILabel!
    @IBOutlet weak var settingsPrompt: UIStackView!

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        guard presentedViewController == nil else { return }

        if everythingAvailable {
            presentImagePicker()
        } else {
            cameraNotAvailable.isHidden = false
            photosNotAvailable.isHidden = false
            motionNotAvailable.isHidden = false
            settingsPrompt.isHidden = false
        }

    }

    // MARK: Interface Builder actions

    @IBAction func settingsTapped(_ sender: Any) {
        openSettings()
    }

    // MARK: Private methods

    private func presentImagePicker() {
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

        present(imagePicker, animated: false, completion: nil)
    }

    private func dismissImagePicker() {
        guard presentedViewController is UIImagePickerController else { return }

        dismiss(animated: false) {
            OperationQueue.main.addOperation {
                self.presentImagePicker()
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

    // MARK: Private properties

    private var everythingAvailable: Bool {
        cameraAvailable && photosAvailable && motionAvailable
    }

    private var cameraAvailable = false
    private var photosAvailable = false
    private var motionAvailable = false

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


// MARK: - Device capabilities and permissions

extension ViewController {

    private func determineCameraAvailability() {
        guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) else {
            cameraAvailable = false
            return
        }

        guard UIImagePickerController.isCameraDeviceAvailable(.rear) || UIImagePickerController.isCameraDeviceAvailable(.front) else {
            cameraAvailable = false
            return
        }

        AVCaptureDevice.requestAccess(for: AVMediaType.video) { permissionGranted in
            OperationQueue.main.addOperation {
                self.cameraAvailable = permissionGranted
            }
        }
    }

}
