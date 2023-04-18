//
//  ViewController.swift
//  Aim Straight
//
// © 2023 Stephen Lardieri
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var settings: UIButton!
    @IBOutlet weak var cameraNotAvailable: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        guard presentedViewController == nil else { return }

        if canPresentImagePicker() {
            presentImagePicker()
        } else {
            cameraNotAvailable.isHidden = false
        }

    }

    @IBAction func settingsTapped(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        guard UIApplication.shared.canOpenURL(settingsUrl) else { return }

        UIApplication.shared.open(settingsUrl) { _ in
            exit(0)
        }
    }
    
    private func canPresentImagePicker() -> Bool {
        guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) else {
            return false
        }

        guard UIImagePickerController.isCameraDeviceAvailable(.rear) || UIImagePickerController.isCameraDeviceAvailable(.front) else {
            return false
        }

        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
            case .notDetermined:
                break

            case .denied, .restricted:
                settings.isHidden = false
                return false

            case .authorized:
                return true

            @unknown default:
                return false
        }

        // UIImagePickerController will ask for permission. No need to do it explicitly.
        return true
    }

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

}


// MARK: - UIImagePickerControllerDelegate

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        exit(0)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        // TODO: Save image to library.

        dismissImagePicker()
    }

}
