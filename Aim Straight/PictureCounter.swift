//
//  PictureCounter.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import Foundation

class PictureCounter {

    init() {
        pictureCounter = Self.readPictureCounter()
    }

    @discardableResult
    func increment() -> Int {
        pictureCounter += 1
        Self.writePictureCounter(pictureCounter)
        return pictureCounter
    }

    private(set) var pictureCounter: Int

}


private extension PictureCounter {

    static func readPictureCounter() -> Int {
        return userDefaults.integer(forKey: key)
    }

    static func writePictureCounter(_ newValue: Int) {
        userDefaults.set(newValue, forKey: key)
    }

    static let key = "PictureCounter"
    static let userDefaults = UserDefaults.standard

}
