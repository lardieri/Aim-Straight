//
//  ViewModel.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import Foundation
import CoreMotion

protocol ViewModelDelegate: AnyObject {
    func viewModelUpdated()
}


class ViewModel {

    struct Attitude {
        let pitch: Double
        let roll: Double
    }

    weak var delegate: ViewModelDelegate?

    var gravity = CMAcceleration() {
        didSet {
            guard gravity != oldValue else { return }

#if DEBUG
            Self.printAttitude(gravity: gravity)
#endif

            delegate?.viewModelUpdated()
        }
    }

    func getCurrentAttitude() -> Attitude {
        return Self.attitude(gravity: self.gravity)
    }

    fileprivate enum DeviceAxis {
        case X // Volume button (-) to power button (+)
        case Y // Home button (-) to front camera (+)
        case Z // Apple logo (-) to the screen (+)
    }

    private static func deviceAxisPointingUp(_ gravity: CMAcceleration) -> (DeviceAxis, FloatingPointSign) {
        // Must negate the sign of the gravity vector component, because the gravity vector points *down* to the center of the Earth.
        //                                                                                   ↓
        if abs(gravity.x) > abs(gravity.y) && abs(gravity.x) > abs(gravity.z) { return (.X, (-gravity.x).sign) }
        if abs(gravity.y) > abs(gravity.x) && abs(gravity.y) > abs(gravity.z) { return (.Y, (-gravity.y).sign) }
        return (.Z, (-gravity.z).sign)
    }

    private static func attitude(gravity: CMAcceleration) -> Attitude {
        let (axis, sign) = deviceAxisPointingUp(gravity)

        let (pitch, roll) = switch (axis, sign) {
            case (.X, .plus):  (pitch:  gravity.z, roll: -gravity.y)
            case (.X, .minus): (pitch:  gravity.z, roll:  gravity.y)
            case (.Y, .plus):  (pitch:  gravity.z, roll:  gravity.x)
            case (.Y, .minus): (pitch:  gravity.z, roll: -gravity.x)
            case (.Z, .plus):  (pitch: -gravity.y, roll:  gravity.x)
            case (.Z, .minus): (pitch:  gravity.y, roll:  gravity.x)
        }

        let normalizedPitch = pitch.clamped
        let normalizedRoll = roll.clamped

        let attitude = Attitude(pitch: normalizedPitch, roll: normalizedRoll)
        return attitude
    }

    private static func printAttitude(gravity: CMAcceleration) {
        func format(_ d: Double) -> String {
            return String(format: "%+.2f", d)
        }

        let x = format(gravity.x)
        let y = format(gravity.y)
        let z = format(gravity.z)
        let (axis, sign) = deviceAxisPointingUp(gravity)
        let attitude = attitude(gravity: gravity)
        let pitch = format(attitude.pitch)
        let roll = format(attitude.roll)

        print("Gravity vector: (x: \(x), y: \(y), z: \(z))  Axis pointing up: \(sign)\(axis)  Pitch: \(pitch)  Roll: \(roll)")
    }

}


extension ViewModel.DeviceAxis: CustomStringConvertible {
    var description: String {
        switch self {
            case .X: "X"
            case .Y: "Y"
            case .Z: "Z"
        }
    }
}


extension FloatingPointSign: CustomStringConvertible {
    public var description: String {
        switch self {
            case .plus: "+"
            case .minus: "-"
        }
    }
}
