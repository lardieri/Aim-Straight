//
//  Vector math.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import Foundation
import CoreMotion

extension CMAcceleration {

    var magnitude: Double {
        return sqrt(
            pow(x, 2.0) + pow(y, 2.0) + pow(z, 2.0)
        )
    }

    enum Axis {
        case x
        case y
        case z
    }

    var dominantAxis: Axis {
        if abs(x) > abs(y) && abs(x) > abs(z) { return .x }
        if abs(y) > abs(x) && abs(y) > abs(z) { return .y }
        return .z
    }

    var pitch: Double {
        switch dominantAxis {
            case .x:
                return z

            case .y:
                return z

            case .z:
                return x
        }
    }

    var roll: Double {
        switch dominantAxis {
            case .x:
                return y

            case .y:
                return x

            case .z:
                return y
        }
    }

}
