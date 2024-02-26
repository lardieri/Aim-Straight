//
//  TiltView.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit

@IBDesignable
class TiltView: UIView {

    // MARK: Constants

    private let lineWidth: CGFloat = 1.0
    private let thickness: CGFloat = 2.0
    private let tiltedStrokeColor: CGColor = UIColor.red.cgColor
    private let straightStrokeColor: CGColor = UIColor.white.cgColor
    private let tiltedFillColor: CGColor = UIColor.white.cgColor
    private let straightfillColor: CGColor = UIColor.green.cgColor

    // MARK: Public properties

    var viewModel: ViewModel? = nil {
        willSet {
            viewModel?.delegate = nil
        }

        didSet {
            viewModel?.delegate = self
        }
    }

    var overlayIsHidden: Bool = false

    // MARK: Design-time properties

#if TARGET_INTERFACE_BUILDER

    @IBInspectable var pitch: Double = 0.0 {
        didSet {
            pitch = pitch.clamped
        }
    }

    @IBInspectable var roll: Double = 0.0 {
        didSet {
            roll = roll.clamped
        }
    }

#endif

    // MARK: View lifecycle methods

    override func draw(_ rect: CGRect) {
        let pitch: Double
        let roll: Double

#if TARGET_INTERFACE_BUILDER

        pitch = self.pitch
        roll = self.roll

#else

        guard let attitude = viewModel?.getCurrentAttitude() else { return }
        pitch = attitude.pitch
        roll = attitude.roll

#endif

        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.saveGState()
        defer { ctx.restoreGState() }

        draw(inContext: ctx, pitch: pitch, roll: roll)
    }

    // MARK: Drawing

    private func draw(inContext ctx: CGContext, pitch: Double, roll: Double) {
        
        func setColor(forAngle angle: Double) {
            if abs(angle) < 0.01 {
                ctx.setStrokeColor(straightStrokeColor)
                ctx.setFillColor(straightfillColor)
            } else {
                ctx.setStrokeColor(tiltedStrokeColor)
                ctx.setFillColor(tiltedFillColor)
            }
        }

        let bounds = self.bounds
        let width = bounds.width
        let height = bounds.height

        let widthOneThird = (width / 3.0) + bounds.origin.x
        let widthTwoThirds = (width * 2.0 / 3.0) + bounds.origin.x
        let heightOneThird = (height / 3.0) + bounds.origin.y
        let heightTwoThirds = (height * 2.0 / 3.0) + bounds.origin.y

        let widthOneSixth = width / 6.0
        let heightOneSixth = height / 6.0

        let widthOffset = pitch * widthOneSixth
        let heightOffset = roll * heightOneSixth

        // Left vertical bar
        let lvStart = CGPoint(
            x: widthOneThird + widthOffset,
            y: bounds.minY
        )

        let lvEnd = CGPoint(
            x: widthOneThird - widthOffset,
            y: bounds.maxY
        )

        // Right vertical bar
        let rvStart = CGPoint(
            x: widthTwoThirds - widthOffset,
            y: bounds.minY
        )

        let rvEnd = CGPoint(
            x: widthTwoThirds + widthOffset,
            y: bounds.maxY
        )

        // Top horizontal bar
        let thStart = CGPoint(
            x: bounds.minX,
            y: heightOneThird - heightOffset
        )

        let thEnd = CGPoint(
            x: bounds.maxX,
            y: heightOneThird + heightOffset
        )

        // Bottom horizontal bar
        let bhStart = CGPoint(
            x: bounds.minX,
            y: heightTwoThirds + heightOffset
        )

        let bhEnd = CGPoint(
            x: bounds.maxX,
            y: heightTwoThirds - heightOffset
        )

        ctx.setLineWidth(lineWidth)
        setColor(forAngle: pitch)

        ctx.clear(bounds)

        ctx.beginPath()
        ctx.move(to: CGPoint(x: lvStart.x - thickness, y: lvStart.y))
        ctx.addLine(to: CGPoint(x: lvEnd.x - thickness, y: lvEnd.y))
        ctx.addLine(to: CGPoint(x: lvEnd.x + thickness, y: lvEnd.y))
        ctx.addLine(to: CGPoint(x: lvStart.x + thickness, y: lvStart.y))
        ctx.closePath()
        ctx.drawPath(using: .fillStroke)

        ctx.beginPath()
        ctx.move(to: CGPoint(x: rvStart.x - thickness, y: rvStart.y))
        ctx.addLine(to: CGPoint(x: rvEnd.x - thickness, y: rvEnd.y))
        ctx.addLine(to: CGPoint(x: rvEnd.x + thickness, y: rvEnd.y))
        ctx.addLine(to: CGPoint(x: rvStart.x + thickness, y: rvStart.y))
        ctx.closePath()
        ctx.drawPath(using: .fillStroke)

        setColor(forAngle: roll)

        ctx.beginPath()
        ctx.move(to: CGPoint(x: thStart.x, y: thStart.y - thickness))
        ctx.addLine(to: CGPoint(x: thEnd.x, y: thEnd.y - thickness))
        ctx.addLine(to: CGPoint(x: thEnd.x, y: thEnd.y + thickness))
        ctx.addLine(to: CGPoint(x: thStart.x, y: thStart.y + thickness))
        ctx.closePath()
        ctx.drawPath(using: .fillStroke)

        ctx.beginPath()
        ctx.move(to: CGPoint(x: bhStart.x, y: bhStart.y - thickness))
        ctx.addLine(to: CGPoint(x: bhEnd.x, y: bhEnd.y - thickness))
        ctx.addLine(to: CGPoint(x: bhEnd.x, y: bhEnd.y + thickness))
        ctx.addLine(to: CGPoint(x: bhStart.x, y: bhStart.y + thickness))
        ctx.closePath()
        ctx.drawPath(using: .fillStroke)
    }

    // MARK: Private properties

    private weak var lastNeedsDisplayOperation: Operation? = nil

}


extension TiltView: ViewModelDelegate {

    func viewModelUpdated() {
        guard !overlayIsHidden else { return }

        if let lastNeedsDisplayOperation = lastNeedsDisplayOperation {
            lastNeedsDisplayOperation.cancel()
        }

        let operation = BlockOperation {
            if !self.isHidden {
                self.setNeedsDisplay()
            }
        }

        // Let main queue operations that change self.isHidden jump ahead.
        operation.queuePriority = .low
        lastNeedsDisplayOperation = operation
        OperationQueue.main.addOperation(operation)
    }

}
