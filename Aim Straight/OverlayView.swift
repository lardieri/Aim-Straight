//
//  OverlayView.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit
import AVFoundation


class OverlayView: UIView {

    // MARK: Storyboard subviews

    @IBOutlet weak var tiltView: TiltView?
    @IBOutlet weak var diagnosticView: DiagnosticView? {
        didSet {
            #if DEBUG
            diagnosticView?.isHidden = false
            #endif
        }
    }

    @IBOutlet weak var tipJarButton: UIButton! {
        didSet {
            if UIDevice.current.userInterfaceIdiom == .pad {
                guard var buttonConfig = tipJarButton.configuration else { return }
                let symbolConfig = buttonConfig.preferredSymbolConfigurationForImage
                let largeConfig = UIImage.SymbolConfiguration(pointSize: 35.0)
                let newSymbolConfig = symbolConfig?.applying(largeConfig)
                buttonConfig.preferredSymbolConfigurationForImage = newSymbolConfig
                tipJarButton.configuration = buttonConfig
            }
        }
    }

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

        if UIDevice.current.userInterfaceIdiom == .pad {
            let maskView = Self.createMaskView()
            maskView.frame = tiltView!.bounds
            maskView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            tiltView!.mask = maskView
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        tiltView!.mask?.frame = tiltView!.bounds
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let tipJarPoint = convert(point, to: tipJarButton)
        return tipJarButton.hitTest(tipJarPoint, with: event)
    }

    // MARK: Layout

    private func clearConstraints() {
        constraints
            .filter { $0.firstItem === tiltView }
            .forEach { $0.isActive = false }
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

    // MARK: UI events

    @IBAction func tipJarButtonTapped(_ sender: UIButton) {
        print("Tip Jar tapped")
    }
    
    // MARK: Public properties

    var viewModel: ViewModel? = nil {
        willSet {
            viewModel?.delegate = nil
            diagnosticView?.viewModel = nil
            tiltView?.viewModel = nil
        }

        didSet {
            tiltView?.viewModel = viewModel
            diagnosticView?.viewModel = viewModel
            viewModel?.delegate = self
        }
    }

    // MARK: Private properties

    private weak var lastNeedsDisplayOperation: Operation? = nil

}


extension OverlayView {

    private static func createMaskView() -> UIView {
        let zoomWidth = 64.0
        let opaqueWidth = 1.0
        let controlsWidth = 112.0

        let width = zoomWidth + opaqueWidth + controlsWidth
        let height = 1.0
        let size = CGSize(width: width, height: height)
        let bounds = CGRect(origin: .zero, size: size)

        let opaqueOrigin = CGPoint(x: zoomWidth, y: 0.0)
        let opaqueSize = CGSize(width: opaqueWidth, height: height)
        let opaqueBounds = CGRect(origin: opaqueOrigin, size: opaqueSize)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setShouldAntialias(false)

        ctx.clear(bounds)

        ctx.setFillColor(gray: 1.0, alpha: 1.0)
        ctx.fill([opaqueBounds])

        let originalImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()

        let capInsets = UIEdgeInsets(top: 0.0, left: zoomWidth, bottom: 0.0, right: controlsWidth)
        let maskImage = originalImage.resizableImage(withCapInsets: capInsets, resizingMode: .stretch)

        let maskView = UIImageView(image: maskImage)
        maskView.contentMode = .scaleToFill

        return maskView
    }

}


extension OverlayView: ViewModelDelegate {

    func viewModelUpdated() {
        if let lastNeedsDisplayOperation = lastNeedsDisplayOperation,
           !lastNeedsDisplayOperation.isFinished {
            return
        }

        let operation = BlockOperation {
            if !self.isHidden {
                self.tiltView?.setNeedsDisplay()
                self.diagnosticView?.update()
            }
        }

        // Let main queue operations that change self.isHidden jump ahead.
        operation.queuePriority = .low
        lastNeedsDisplayOperation = operation
        OperationQueue.main.addOperation(operation)
    }

}
