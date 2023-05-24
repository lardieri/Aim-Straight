//
//  TiltView.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit


protocol TiltViewDelegate {
    var pitch: Double { get }
    var roll: Double { get }
}


@IBDesignable
class TiltView: UIView {

    // MARK: Constants

    private let lineWidth: CGFloat = 1.0
    private let thickness: CGFloat = 1.0
    private let strokeColor: CGColor = UIColor.white.cgColor
    private let tiltedFillColor: CGColor = UIColor.red.cgColor
    private let straightfillColor: CGColor = UIColor.green.cgColor

    // MARK: Public properties

    var delegate: TiltViewDelegate? = nil
    var overlayIsHidden: Bool = false

    @IBInspectable var pitch: Double = 0.0 {
        didSet {
            pitch = pitch.normalized
        }
    }

    @IBInspectable var roll: Double = 0.0 {
        didSet {
            roll = roll.normalized
        }
    }

    // MARK: Public methods

    func gravityUpdated() {
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

    // MARK: View lifecycle methods

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.saveGState()
        defer { ctx.restoreGState() }

        let pitch = delegate?.pitch ?? self.pitch
        let roll = delegate?.roll ?? self.roll

        draw(inContext: ctx, pitch: pitch, roll: roll)
    }

    // MARK: Drawing

    private func draw(inContext ctx: CGContext, pitch: Double, roll: Double) {
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

        ctx.setStrokeColor(strokeColor)
        ctx.setLineWidth(lineWidth)

        if abs(pitch) < 0.01 {
            ctx.setFillColor(straightfillColor)
        } else {
            ctx.setFillColor(tiltedFillColor)
        }

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

        if abs(roll) < 0.01 {
            ctx.setFillColor(straightfillColor)
        } else {
            ctx.setFillColor(tiltedFillColor)
        }

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
