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

}


extension CMAcceleration: Equatable {

    public static func == (lhs: CMAcceleration, rhs: CMAcceleration) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }

}


extension Double {

    var clamped: Double {
        let clampedValue = min(1.0, max(-1.0, self))
        let roundedValue = (clampedValue * 100.0).rounded() / 100.0
        return roundedValue
    }

}
