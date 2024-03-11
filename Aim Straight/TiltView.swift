//
//  TiltView.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import UIKit

// MARK: - Constants

fileprivate let strokeThickness: CGFloat = 1.0
fileprivate let fillThickness: CGFloat = 2.0
fileprivate let majorThickness = strokeThickness + fillThickness
fileprivate let minorThickness = fillThickness
fileprivate let majorOffset = majorThickness / 2.0
fileprivate let minorOffset = minorThickness / 2.0

fileprivate let tiltedStrokeColor: CGColor = UIColor.red.cgColor
fileprivate let straightStrokeColor: CGColor = UIColor.white.cgColor
fileprivate let tiltedFillColor: CGColor = UIColor.white.cgColor
fileprivate let straightfillColor: CGColor = UIColor.green.cgColor

// MARK: -

@IBDesignable
class TiltView: UIView {

    var overlayIsHidden: Bool = false

    // MARK: Public properties

    var viewModel: ViewModel? = nil

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
        let screen = self.window!.screen
        let fixedBounds = self.coordinateSpace.convert(bounds, to: screen.fixedCoordinateSpace)

        func setColor(forDeviation deviation: Double) {
            if abs(deviation) < 0.01 {
                ctx.setStrokeColor(straightStrokeColor)
                ctx.setFillColor(straightfillColor)
            } else {
                ctx.setStrokeColor(tiltedStrokeColor)
                ctx.setFillColor(tiltedFillColor)
            }
        }

        func toViewCoordinates(_ screenPoint: CGPoint) -> CGPoint {
            self.coordinateSpace.convert(screenPoint, from: screen.fixedCoordinateSpace)
        }

        func drawPolygon(_ screenPoints: [CGPoint]) {
            ctx.beginPath()
            ctx.addLines(between: screenPoints.map { toViewCoordinates($0) } )
            ctx.closePath()
            ctx.drawPath(using: .fillStroke)
        }

        let leftEdge = fixedBounds.minX
        let rightEdge = fixedBounds.maxX
        let topEdge = fixedBounds.minY
        let bottomEdge = fixedBounds.maxY
        let width = fixedBounds.width
        let height = fixedBounds.height

        let leftPitchCenter = leftEdge + (width / 3.0)
        let rightPitchCenter = rightEdge - (width / 3.0)
        let topRollCenter = topEdge + (height / 3.0)
        let bottomRollCenter = bottomEdge - (height / 3.0)

        let pitchMaxOffset = width / 8.0
        let rollMaxOffset = height / 8.0

        let pitchOffset = pitch * pitchMaxOffset
        let rollOffset = roll * rollMaxOffset

        // Left pitch bar
        let leftPitchStart = CGPoint(
            x: leftPitchCenter + pitchOffset,
            y: topEdge
        )

        let leftPitchEnd = CGPoint(
            x: leftPitchCenter - pitchOffset,
            y: bottomEdge
        )

        let leftPitchPoints: [CGPoint] = [
            CGPoint(x: leftPitchStart.x - majorOffset, y: leftPitchStart.y + minorOffset),
            CGPoint(x: leftPitchEnd.x - majorOffset, y: leftPitchEnd.y - minorOffset),
            CGPoint(x: leftPitchEnd.x + majorOffset, y: leftPitchEnd.y - minorOffset),
            CGPoint(x: leftPitchStart.x + majorOffset, y: leftPitchStart.y + minorOffset)
        ]

        // Right pitch bar
        let rightPitchStart = CGPoint(
            x: rightPitchCenter - pitchOffset,
            y: topEdge
        )

        let rightPitchEnd = CGPoint(
            x: rightPitchCenter + pitchOffset,
            y: bottomEdge
        )

        let rightPitchPoints: [CGPoint] = [
            CGPoint(x: rightPitchStart.x - majorOffset, y: rightPitchStart.y + minorOffset),
            CGPoint(x: rightPitchEnd.x - majorOffset, y: rightPitchEnd.y - minorOffset),
            CGPoint(x: rightPitchEnd.x + majorOffset, y: rightPitchEnd.y - minorOffset),
            CGPoint(x: rightPitchStart.x + majorOffset, y: rightPitchStart.y + minorOffset)
        ]

        // Top roll bar
        let topRollStart = CGPoint(
            x: leftEdge,
            y: topRollCenter - rollOffset
        )

        let topRollEnd = CGPoint(
            x: rightEdge,
            y: topRollCenter + rollOffset
        )

        let topRollPoints: [CGPoint] = [
            CGPoint(x: topRollStart.x + minorOffset, y: topRollStart.y - majorOffset),
            CGPoint(x: topRollEnd.x - minorOffset, y: topRollEnd.y - majorOffset),
            CGPoint(x: topRollEnd.x - minorOffset, y: topRollEnd.y + majorOffset),
            CGPoint(x: topRollStart.x + minorOffset, y: topRollStart.y + majorOffset)
        ]

        // Bottom roll bar
        let bottomRollStart = CGPoint(
            x: leftEdge,
            y: bottomRollCenter + rollOffset
        )

        let bottomRollEnd = CGPoint(
            x: rightEdge,
            y: bottomRollCenter - rollOffset
        )

        let bottomRollPoints: [CGPoint] = [
            CGPoint(x: bottomRollStart.x + minorOffset, y: bottomRollStart.y - majorOffset),
            CGPoint(x: bottomRollEnd.x - minorOffset, y: bottomRollEnd.y - majorOffset),
            CGPoint(x: bottomRollEnd.x - minorOffset, y: bottomRollEnd.y + majorOffset),
            CGPoint(x: bottomRollStart.x + minorOffset, y: bottomRollStart.y + majorOffset)
        ]

        // Draw!
        ctx.clear(bounds)
        ctx.setLineWidth(strokeThickness)

        setColor(forDeviation: pitch)
        drawPolygon(leftPitchPoints)
        drawPolygon(rightPitchPoints)

        setColor(forDeviation: roll)
        drawPolygon(topRollPoints)
        drawPolygon(bottomRollPoints)
    }

}
