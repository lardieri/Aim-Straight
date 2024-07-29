//
//  TipJarBusinessLogic.swift
//  Aim Straight
//
//  © 2023 Stephen Lardieri
//

import Foundation

fileprivate let minPicturesTakenSinceLastPayment = 5
fileprivate let minDaysSinceLastPayment = 182

protocol TipJarBusinessLogicDelegate: AnyObject {
    func userMadeTipPayment()
}

class TipJarBusinessLogic {
    
    init() {
        transactionMonitor.delegate = self
    }

    func showTipJarAfterTakingPicture() -> Bool {
        let counter = pictureCounter.increment()
        guard counter >= minPicturesTakenSinceLastPayment else {
            return false
        }

        let lastPaymentDate = paymentRecorder.lastPaymentDate
        let now = Date.now
        let timeSinceLastPayment = now.timeIntervalSince(lastPaymentDate)
        let daysSinceLastPayment = timeSinceLastPayment / (60 * 60 * 24)
        guard daysSinceLastPayment >= Double(minDaysSinceLastPayment) else {
            return false
        }

        return true
    }

    weak var delegate: TipJarBusinessLogicDelegate?

    private let pictureCounter = PictureCounter()
    private let paymentRecorder = LastPaymentDateRecorder()
    private let transactionMonitor = StoreKitTransactionMonitor()

}


// MARK: -

extension TipJarBusinessLogic: StoreKitTransactionMonitorDelegate {

    func paymentTransactionFinished() {
        paymentRecorder.recordPayment()
        pictureCounter.reset()
        delegate?.userMadeTipPayment()
    }

}
