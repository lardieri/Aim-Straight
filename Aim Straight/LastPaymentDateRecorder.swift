//
//  LastPaymentDateRecorder.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import Foundation

class LastPaymentDateRecorder {

    init() {
        lastPaymentDate = Self.readLastPaymentDate()
    }

    func recordPayment() {
        lastPaymentDate = .now
        Self.writeLastPaymentDate(lastPaymentDate)
    }

    private(set) var lastPaymentDate: Date

}


private extension LastPaymentDateRecorder {

    static func readLastPaymentDate() -> Date {
        let interval = userDefaults.double(forKey: key)
        let date = Date(timeIntervalSince1970: interval)
        return date
    }

    static func writeLastPaymentDate(_ date: Date) {
        let interval = date.timeIntervalSince1970
        userDefaults.set(Double(interval), forKey: key)
    }

    static let key = "LastPaymentDate"
    static let userDefaults = UserDefaults.standard

}
