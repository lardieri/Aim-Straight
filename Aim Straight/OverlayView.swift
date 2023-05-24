//
//  OverlayView.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit
import AVFoundation


class OverlayView: UIView {

    @IBOutlet weak var tiltView: TiltView?

    // MARK: View lifecycle

    override var isHidden: Bool {
        didSet {
            tiltView?.overlayIsHidden = isHidden
        }
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        clearConstraints()
    }

    override func didMoveToWindow() {
        guard window != nil else { return }
        self.frame = superview!.bounds
        activateConstraints()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }

    // MARK: Public methods

    func gravityUpdated() {
        tiltView!.gravityUpdated()
    }

    // MARK: Layout

    private func clearConstraints() {
        constraints.forEach { $0.isActive = false }
    }

    private func activateConstraints() {
        tiltView!.translatesAutoresizingMaskIntoConstraints = false

        guard let cameraPreview = window!.firstSubviewWithLayer(ofType: AVCaptureVideoPreviewLayer.self) else { return }
        let anchorView: UIView

        // On iPad, the grandparent of the preview applies a transform when the device is rotated.
        // On iPhone, the preview doesn't take up the full screen.
        if UIDevice.current.userInterfaceIdiom == .pad {
            anchorView = cameraPreview.superview!.superview!.superview!
        } else {
            anchorView = cameraPreview
        }

        [
            NSLayoutConstraint(item: tiltView!, attribute: .centerX, relatedBy: .equal, toItem: anchorView, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: tiltView!, attribute: .centerY, relatedBy: .equal, toItem: anchorView, attribute: .centerY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: tiltView!, attribute: .width, relatedBy: .equal, toItem: anchorView, attribute: .width, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: tiltView!, attribute: .height, relatedBy: .equal, toItem: anchorView, attribute: .height, multiplier: 1.0, constant: 0.0),
        ].forEach { $0.isActive = true }
    }

}


extension OverlayView {

    var tiltViewDelegate: TiltViewDelegate? {
        get {
            return tiltView!.delegate
        }

        set {
            tiltView!.delegate = newValue
        }
    }

}
