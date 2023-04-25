//
//  TiltView.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit

@IBDesignable
class TiltView: UIView {

    let lineWidth: CGFloat = 1.0
    let thickness: CGFloat = 1.0
    let strokeColor: CGColor = UIColor.white.cgColor
    let tiltedFillColor: CGColor = UIColor.red.cgColor
    let straightfillColor: CGColor = UIColor.green.cgColor

    @propertyWrapper
    struct Normalized {
        private var value: Double = 0.0
        var wrappedValue: Double {
            get {
                return value
            }

            set {
                let clampedValue = min(1.0, max(-1.0, newValue))
                let roundedValue = round(clampedValue * 1000.0) / 1000.0
                value = roundedValue
            }
        }
    }

    @IBInspectable
    @Normalized var normalizedPitch: Double {
        didSet {
            if oldValue != normalizedPitch {
                OperationQueue.main.addOperation {
                    self.setNeedsDisplay()
                }
            }
        }
    }

    @IBInspectable
    @Normalized var normalizedRoll: Double {
        didSet {
            if oldValue != normalizedRoll {
                OperationQueue.main.addOperation {
                    self.setNeedsDisplay()
                }
            }
        }
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.saveGState()
        defer { ctx.restoreGState() }

        let bounds = self.bounds
        let width = bounds.width
        let height = bounds.height

        let widthOneThird = (width / 3.0) + bounds.origin.x
        let widthTwoThirds = (width * 2.0 / 3.0) + bounds.origin.x
        let heightOneThird = (height / 3.0) + bounds.origin.y
        let heightTwoThirds = (height * 2.0 / 3.0) + bounds.origin.y

        let widthOneSixth = width / 6.0
        let heightOneSixth = height / 6.0

        let widthOffset = normalizedPitch * widthOneSixth
        let heightOffset = normalizedRoll * heightOneSixth

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

        if abs(normalizedPitch) < 0.01 {
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

        if abs(normalizedRoll) < 0.01 {
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

}
