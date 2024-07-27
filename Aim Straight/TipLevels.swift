//
//  Tip Levels.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import Foundation

enum TipLevel: String, CaseIterable {
    case budget   = "AimStraight.TipBudget"
    case standard = "AimStraight.TipStandard"
    case pro      = "AimStraight.TipPro"
}

extension TipLevel {
    static let productIdentifiers = TipLevel.allCases.map { $0.rawValue }
}
